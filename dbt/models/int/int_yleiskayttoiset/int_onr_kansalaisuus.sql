{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid','priorisoitu_kansalaisuus']}
    ]
    )
}}

with raw as not materialized (
    select
        henkilo_oid,
        kansalaisuus
    from {{ ref('int_onr_henkilo') }}
),

maa_valtioryhma as (
    select distinct maa_koodiarvo
    from {{ ref('int_koodisto_maa_valtioryhma') }}
    where valtioryhma_koodiarvo in ('EU', 'ETA')
),

kansalaisuus_riveille as not materialized (
    select
        henkilo_oid,
        (jsonb_array_elements(kansalaisuus) ->> 0) as kansalaisuus --noqa: CV11
    from raw
),

kansalaisuus_jarjestys as (
    select
        henkilo_oid,
        kansalaisuus,
        case
            when kansalaisuus = '246' then 1
            when kansalaisuus in (
                select maa_koodiarvo from maa_valtioryhma
            ) then 2
            else 3
        end
        as jarjestys
    from kansalaisuus_riveille
),

haluttu_kansalaisuus as (
    select
        henkilo_oid,
        kansalaisuus,
        jarjestys as kansalaisuusluokka,
        row_number() over (partition by henkilo_oid order by jarjestys) as haluttu_kansalaisuus
    from kansalaisuus_jarjestys
),

final as (
    select
        henkilo_oid,
        kansalaisuus,
        kansalaisuusluokka,
        haluttu_kansalaisuus = 1 as priorisoitu_kansalaisuus
    from haluttu_kansalaisuus
)

select * from final