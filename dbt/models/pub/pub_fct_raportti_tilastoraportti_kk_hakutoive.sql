{{
    config(
        indexes = [
            {'columns': ['hakukohde_oid']}
        ]
    )
}}

with hakutoive as (
    select * from {{ ref('pub_dim_hakutoive') }}
),

hakukohde as (
    select * from {{ ref('pub_dim_hakukohde') }}
),

henkilo as (
    select * from {{ ref('pub_dim_henkilo') }}
),

valintarekisteri as (
    select * from {{ ref('int_valintarekisteri') }}
),

hakemus as (
    select * from {{ ref('int_hakutoive_kk') }}
),

maksuvelvollisuus as (
    select * from {{ ref('pub_dim_maksuvelvollisuus') }}
),

final as (
    select
        hato.hakutoive_id,
        henk.master_oid as henkilo_oid,
        hato.hakukohde_oid,
        henk.aidinkieliluokka as aidinkieli,
        coalesce(henk.kansalaisuusluokka, 3) as kansalaisuusluokka,
        henk.sukupuoli,
        coalesce(henk.kansalaisuus, '999') as kansalaisuus,
        coalesce(hato.ensikertalainen, false) as ensikertalainen,
        hakutoivenumero = '1' as ensisijainen,
        (hato.valintatieto = 'HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU')
        or (hato.valintatieto = 'VARASIJALTA_HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU')
        or hato.valintatieto = 'PERUNUT'
        as hyvaksytty,
        vare.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI', 'EHDOLLISESTI_VASTAANOTTANUT') as vastaanottanut,
        (
            hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
            and upper(vare.ilmoittautumisen_tila) in
            ('LASNA_SYKSY', 'POISSA_KEVAT', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')
        )
        or (
            hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
            and upper(vare.ilmoittautumisen_tila) in ('LASNA_KEVAT', 'POISSA_SYKSY', 'LASNA', 'LASNA_KOKO_LUKUVUOSI')
        )
        or upper(vare.ilmoittautumisen_tila) in ('LASNA', 'LASNA_KOKO_LUKUVUOSI')
        as lasna,
        (
            hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_s#1'
            and upper(vare.ilmoittautumisen_tila) in ('POISSA_SYKSY', 'POISSA_KOKO_LUKUVUOSI')
        )
        or (
            hako.koulutuksen_alkamiskausi_koodiuri = 'kausi_k#1'
            and upper(vare.ilmoittautumisen_tila) in ('POISSA_KEVAT', 'POISSA_KOKO_LUKUVUOSI')
        )
        or upper(vare.ilmoittautumisen_tila) in ('POISSA', 'POISSA_KOKO_LUKUVUOSI')
        as poissa,
        (
            vare.ilmoittautumisen_tila is not null
            and vare.ilmoittautumisen_tila not in ('EI_TEHTY', 'EI_ILMOITTAUTUNUT')
        ) as ilmoittautunut,
        mave.maksuvelvollisuus = 'obligated' as maksuvelvollinen,
        hakutoivenumero = '1' as toive_1,
        hakutoivenumero = '2' as toive_2,
        hakutoivenumero = '3' as toive_3,
        hakutoivenumero = '4' as toive_4,
        hakutoivenumero = '5' as toive_5,
        hakutoivenumero = '6' as toive_6
    from hakutoive as hato
    inner join henkilo as henk on hato.henkilo_hakemus_id = henk.henkilo_hakemus_id
    inner join hakukohde as hako on hato.hakukohde_oid = hako.hakukohde_oid
    left join valintarekisteri as vare on hato.hakukohde_henkilo_id = vare.hakukohde_henkilo_id
    left join hakemus as hake on hato.hakutoive_id = hake.hakutoive_id
    left join maksuvelvollisuus as mave on hato.hakutoive_id = mave.hakutoive_id
)

select * from final
