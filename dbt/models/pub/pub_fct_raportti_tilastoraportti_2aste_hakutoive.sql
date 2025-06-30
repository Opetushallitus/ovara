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
    select * from {{ ref('int_vastaanotto') }}
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
        hato.hakutoive_id,
        henk.master_oid as henkilo_oid,
        hato.hakukohde_oid,
        koul.kansallinenkoulutusluokitus2016koulutusalataso1 as koulutusalataso_1,
        koul.kansallinenkoulutusluokitus2016koulutusalataso2 as koulutusalataso_2,
        koul.kansallinenkoulutusluokitus2016koulutusalataso3 as koulutusalataso_3,
        hato.harkinnanvaraisuuden_syy,
        henk.sukupuoli,
        hato.hakutoivenumero = 1 as ensisijainen,
        hato.valintatieto = 'VARALLA' as varasija,
        (hato.valintatieto = 'HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU') or
            (hato.valintatieto = 'VARASIJALTA_HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU') or
            (hato.valintatieto = 'PERUNUT')
        as hyvaksytty,
        vare.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI', 'EHDOLLISESTI_VASTAANOTTANUT') as vastaanottanut,
        (hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
                and upper(vare.ilmoittautumisen_tila) in
                ('LASNA_SYKSY', 'POISSA_KEVAT', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')) or
            (hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
                and upper(vare.ilmoittautumisen_tila)
                in ('LASNA_KEVAT', 'POISSA_SYKSY', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')) or
            upper(vare.ilmoittautumisen_tila) in ('LASNA', 'LASNA_KOKO_LUKUVUOSI')
        as lasna,
        (hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
            and upper(vare.ilmoittautumisen_tila) in ('POISSA_SYKSY', 'POISSA_KOKO_LUKUVUOSI')) or
            (hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
                and upper(vare.ilmoittautumisen_tila) in ('POISSA_KEVAT', 'POISSA_KOKO_LUKUVUOSI')) or
            upper(vare.ilmoittautumisen_tila) in ('POISSA', 'POISSA_KOKO_LUKUVUOSI')
        as poissa,
        vare.ilmoittautumisen_tila is not null
                and vare.ilmoittautumisen_tila not in ('EI_TEHTY', 'EI_ILMOITTAUTUNUT')
        as ilm_yht,
        hato.hakutoivenumero = 1 as toive_1,
        hato.hakutoivenumero = 2 as toive_2,
        hato.hakutoivenumero = 3 as toive_3,
        hato.hakutoivenumero = 4 as toive_4,
        hato.hakutoivenumero = 5 as toive_5,
        hato.hakutoivenumero = 6 as toive_6,
        hato.hakutoivenumero = 7 as toive_7
    from hakutoive as hato
    inner join hakukohde as hako on hato.hakukohde_oid = hako.hakukohde_oid
    inner join koulutus as koul on hako.koulutus_oid = koul.koulutus_oid
    inner join henkilo as henk on hato.henkilo_hakemus_id = henk.henkilo_hakemus_id
    left join valintarekisteri as vare on hato.hakukohde_henkilo_id = vare.hakukohde_henkilo_id
)

select * from final
