{{
  config(
    materialized = 'table',
    indexes = [
      {'columns':['hakukohde_oid']},
    ]
    )
}}

with hakutoive as (
    select * from {{ ref('pub_dim_hakutoive') }}
),

hakukohde as (
    select * from {{ ref('pub_dim_hakukohde') }}
),

koulutus as (
    select * from {{ ref('pub_dim_koulutus') }}
),

henkilo as (
    select * from {{ ref('pub_dim_henkilo') }}
),

vastaanotto as (
    select * from {{ ref('int_valintarekisteri_vastaanotto') }}
),

ilmoittautuminen as (
    select * from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

valintarekisteri as (
    select
        coalesce(vast.hakukohde_henkilo_id, ilmo.hakukohde_henkilo_id) as hakukohde_henkilo_id,
        vast.vastaanottotieto,
        ilmo.tila as ilmoittautumisen_tila
    from vastaanotto as vast
    full outer join ilmoittautuminen as ilmo on vast.hakukohde_henkilo_id = ilmo.hakukohde_henkilo_id

),

final as (
    select
        hato.hakukohde_oid,
        koul.kansallinenkoulutusluokitus2016koulutusalataso1 as koulutusalataso_1,
        koul.kansallinenkoulutusluokitus2016koulutusalataso2 as koulutusalataso_2,
        koul.kansallinenkoulutusluokitus2016koulutusalataso3 as koulutusalataso_3,
        hato.harkinnanvaraisuuden_syy,
        henk.sukupuoli,
        count(distinct hato.henkilo_oid) as hakijat,
        sum(case when hato.hakutoivenumero = 1 then 1 else 0 end) as ensisijaisia,
        sum(case when valintatapajonot -> 0 ->> 'jonosija' is not null then 1 else 0 end) as varasija,
        sum(case when upper(valintatapajonot -> 0 ->> 'valinnan_tila') = 'HYVAKSYTTY' then 1 else 0 end) as hyvaksytyt,
        sum(case when vare.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI') then 1 else 0 end) as vastaanottaneet,
        sum(case
            when
                hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
                and upper(vare.ilmoittautumisen_tila) in
                ('LASNA_SYKSY', 'POISSA_KEVAT', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')
                then 1
            when
                hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
                and upper(vare.ilmoittautumisen_tila)
                in ('LASNA_KEVAT', 'POISSA_SYKSY', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')
                then 1
            when upper(vare.ilmoittautumisen_tila) in ('LASNA', 'LASNA_KOKO_LUKUVUOSI')
                then 1
            else 0
        end) as lasna,
        sum(case
            when
                hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
                and upper(vare.ilmoittautumisen_tila) in ('POISSA_SYKSY', 'POISSA_KOKO_LUKUVUOSI') then 1
            when
                hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
                and upper(vare.ilmoittautumisen_tila) in ('POISSA_KEVAT', 'POISSA_KOKO_LUKUVUOSI') then 1
            when upper(vare.ilmoittautumisen_tila) in ('LASNA', 'LASNA_KOKO_LUKUVUOSI') then 1
            else 0
        end) as poissa,
        sum(case when vare.ilmoittautumisen_tila is not null then 1 else 0 end) as ilm_yht,
        min(hako.aloituspaikat) as aloituspaikat,
        sum(case when hato.hakutoivenumero = 1 then 1 else 0 end) as toive_1,
        sum(case when hato.hakutoivenumero = 2 then 1 else 0 end) as toive_2,
        sum(case when hato.hakutoivenumero = 3 then 1 else 0 end) as toive_3,
        sum(case when hato.hakutoivenumero = 4 then 1 else 0 end) as toive_4,
        sum(case when hato.hakutoivenumero = 5 then 1 else 0 end) as toive_5,
        sum(case when hato.hakutoivenumero = 6 then 1 else 0 end) as toive_6,
        sum(case when hato.hakutoivenumero = 7 then 1 else 0 end) as toive_7
    from hakutoive as hato
    inner join hakukohde as hako on hato.hakukohde_oid = hako.hakukohde_oid
    inner join koulutus as koul on hako.koulutus_oid = koul.koulutus_oid
    inner join henkilo as henk on hato.henkilo_hakemus_id = henk.henkilo_hakemus_id
    left join valintarekisteri as vare on hato.hakukohde_henkilo_id = vare.hakukohde_henkilo_id
    group by 1, 2, 3, 4, 5, 6

)

select * from final
