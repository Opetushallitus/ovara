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

henkilo as (
    select * from {{ ref('pub_dim_henkilo') }}
),

valintarekisteri as (
    select * from {{ ref('int_valintarekisteri') }}
),

hakemus as (
    select * from {{ ref('int_hakemus_kk') }}
),

final as (
    select
        hato.hakukohde_oid,
        henk.aidinkieliluokka as aidinkieli,
        coalesce(henk.kansalaisuusluokka, 3) as kansalaisuus,
        henk.sukupuoli,
        coalesce(hato.ensikertalainen, false) as ensikertalainen,
        count(distinct hato.henkilo_oid) as hakijat,
        sum(case when hakutoivenumero = '1' then 1 else 0 end) as ensisijaisia,
        sum(1) as hyvaksytyt,
        sum(
            case
                when vare.vastaanottotieto in ('VASTAANOTTANUT_SITOVASTI') then 1
                else 0
            end
        ) as vastaanottaneet,
        sum(1) as lasna,
        sum(0) as poissa,
        count(vare.ilmoittautumisen_tila) as ilm_yht,
        sum(
            case
                when hake.maksuvelvollisuus = 'obligated' then 1
                else 0
            end
        ) as maksuvelvollisia,
        sum(1) as valinnan_aloituspaikat,
        sum(1) as alpa,
        sum(case when hakutoivenumero = '1' then 1 else 0 end) as toive_1,
        sum(case when hakutoivenumero = '2' then 1 else 0 end) as toive_2,
        sum(case when hakutoivenumero = '3' then 1 else 0 end) as toive_3,
        sum(case when hakutoivenumero = '4' then 1 else 0 end) as toive_4,
        sum(case when hakutoivenumero = '5' then 1 else 0 end) as toive_5,
        sum(case when hakutoivenumero = '6' then 1 else 0 end) as toive_6,
        sum(case when hakutoivenumero = '7' then 1 else 0 end) as toive_7
    from hakutoive as hato
    inner join henkilo as henk on hato.henkilo_hakemus_id = henk.henkilo_hakemus_id
    left join valintarekisteri as vare on hato.hakukohde_henkilo_id = vare.hakukohde_henkilo_id
    left join hakemus as hake on hato.hakutoive_id = hake.hakutoive_id
    group by 1, 2, 3, 4, 5

)

select * from final
