{{
  config(
    materialized = 'table',
    indexes = [
      {'columns':['hakukohde_oid']},
      {'columns':['haku_oid']},
      {'columns':['organisaatio_oid']}

    ]
    )
}}

with hakutoive as (
    select * from {{ ref('pub_dim_hakutoive') }}
),

hakemus as (
    select * from {{ ref('pub_fct_hakemus') }}
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

organisaatio as (
    select * from {{ ref('int_organisaatio') }}
),

vastaanotto as (
    select * from {{ ref('int_valintarekisteri_vastaanotto') }}
),

ilmoittautuminen as (
    select * from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

final as (
    select
        hato.hakukohde_oid,
        hako.hakukohde_nimi,
        hake.haku_oid,
        orga.organisaatio_oid,
        hako.oppilaitoksen_opetuskieli,
        koul.kansallinenkoulutusluokitus2016koulutusalataso1 as koulutusalataso_1,
        koul.kansallinenkoulutusluokitus2016koulutusalataso2 as koulutusalataso_2,
        koul.kansallinenkoulutusluokitus2016koulutusalataso3 as koulutusalataso_3,
        orga.sijaintikunta,
        orga.sijaintikunta_nimi,
        orga.sijaintimaakunta,
        orga.sijaintimaakunta_nimi,
        hato.harkinnanvaraisuuden_syy,
        henk.sukupuoli,
        count(distinct hato.henkilo_oid) as hakijat,
        sum (case when hato.hakutoivenumero =1 then 1 else 0 end) as ensisijaisia,
        sum (case when valintatapajonot -> 0 ->> 'jonosija' is not null then 1 else 0 end) as varasija,
        sum (case when upper(valintatapajonot ->0 ->> 'valinnan_tila') ='HYVAKSYTTY' then 1 else 0 end  ) as hyvaksytyt,
        sum (case when vast.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI') then 1 else 0 end) as vastaanottaneet,
        sum (case when upper(ilmo.tila) in ('LASNA','LASNA_KOKO_LUKUVUOSI') then 1 else 0 end ) as lasna,
        sum (case when upper(ilmo.tila) in ('POISSA','POISSA_KOKO_LUKUVUOSI') then 1 else 0 end ) as poissa,
        sum (case when ilmo.tila is not null then 1 else 0 end) as ilm_yht,
        min(hako.aloituspaikat) as aloituspaikat,
        sum (case when hato.hakutoivenumero =1 then 1 else 0 end) as toive_1,
        sum (case when hato.hakutoivenumero =2 then 1 else 0 end) as toive_2,
        sum (case when hato.hakutoivenumero =3 then 1 else 0 end) as toive_3,
        sum (case when hato.hakutoivenumero =4 then 1 else 0 end) as toive_4,
        sum (case when hato.hakutoivenumero =5 then 1 else 0 end) as toive_5,
        sum (case when hato.hakutoivenumero =6 then 1 else 0 end) as toive_6,
        sum (case when hato.hakutoivenumero =7 then 1 else 0 end) as toive_7
    from hakutoive as hato
    join hakemus as hake on hato.hakemus_oid = hake.hakemus_oid
    join hakukohde as hako on hato.hakukohde_oid = hako.hakukohde_oid
    join koulutus as koul on hako.koulutus_oid = koul.koulutus_oid
    join henkilo as henk on hato.henkilo_oid = henk.henkilo_oid and hato.hakemus_oid = henk.hakemus_oid
    left join organisaatio as orga on hako.jarjestyspaikka_oid = orga.organisaatio_oid
    left join vastaanotto as vast on hato.hakukohde_henkilo_id = vast.hakukohde_henkilo_id
    left join ilmoittautuminen as ilmo on hato.hakukohde_henkilo_id  = ilmo.hakukohde_henkilo_id
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14

)

select * from final
