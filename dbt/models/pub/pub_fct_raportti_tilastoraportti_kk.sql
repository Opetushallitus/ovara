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
        hato.hakukohde_oid,
        henk.aidinkieliluokka as aidinkieli,
        coalesce(henk.kansalaisuusluokka, 3) as kansalaisuusluokka,
        henk.sukupuoli,
        coalesce(henk.kansalaisuus, '999') as kansalaisuus,
        coalesce(hato.ensikertalainen, false) as ensikertalainen,
        count(distinct hato.henkilo_oid) as hakijat,
        sum(case when hakutoivenumero = '1' then 1 else 0 end) as ensisijaisia,
        sum(case when ensikertalainen then 1 else 0 end) as ensikertalaisia,
        sum(
            case
                when hato.valintatieto = 'HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU' then 1
                when hato.valintatieto = 'VARASIJALTA_HYVAKSYTTY' and hato.vastaanottotieto is distinct from 'PERUUTETTU' then 1
                when hato.valintatieto = 'PERUNUT' then 1
                else 0
            end
        ) as hyvaksytyt,
        sum(
            case
                when vare.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI', 'EHDOLLISESTI_VASTAANOTTANUT') then 1
                else 0
            end
        ) as vastaanottaneet,
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
            when upper(vare.ilmoittautumisen_tila) in ('POISSA', 'POISSA_KOKO_LUKUVUOSI') then 1
            else 0
        end) as poissa,
        sum(
            case
                when
                    vare.ilmoittautumisen_tila is not null
                    and vare.ilmoittautumisen_tila not in ('EI_TEHTY', 'EI_ILMOITTAUTUNUT')
                    then 1
                else 0
            end
        ) as ilm_yht,
        sum(
            case
                when mave.maksuvelvollisuus = 'obligated' then 1
                else 0
            end
        ) as maksuvelvollisia,
        sum(case when hakutoivenumero = '1' then 1 else 0 end) as toive_1,
        sum(case when hakutoivenumero = '2' then 1 else 0 end) as toive_2,
        sum(case when hakutoivenumero = '3' then 1 else 0 end) as toive_3,
        sum(case when hakutoivenumero = '4' then 1 else 0 end) as toive_4,
        sum(case when hakutoivenumero = '5' then 1 else 0 end) as toive_5,
        sum(case when hakutoivenumero = '6' then 1 else 0 end) as toive_6
    from hakutoive as hato
    inner join henkilo as henk on hato.henkilo_hakemus_id = henk.henkilo_hakemus_id
    inner join hakukohde as hako on hato.hakukohde_oid = hako.hakukohde_oid
    left join valintarekisteri as vare on hato.hakukohde_henkilo_id = vare.hakukohde_henkilo_id
    left join hakemus as hake on hato.hakutoive_id = hake.hakutoive_id
    left join maksuvelvollisuus as mave on hato.hakutoive_id = mave.hakutoive_id

    group by 1, 2, 3, 4, 5, 6

)

select * from final
