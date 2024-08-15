{{
  config(
    indexes=[
        {'columns':['henkilotieto_id','haluttu_kansalaisuus']},
        {'columns':['henkilotieto_kansalaisuus_id']}
        ],
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'henkilotieto_kansalaisuus_id',
    )
}}

with raw as (
    select
        oid as hakemus_oid,
        versio_id,
        henkilo_oid,
        kansalaisuus,
        muokattu,
        dw_metadata_dbt_copied_at
    from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

hakemukset as (
    select
        hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        muokattu,
        dw_metadata_dbt_copied_at
    from raw
),

maa_valtioryhma as (
    select distinct maa_koodiarvo
    from {{ ref('int_koodisto_maa_valtioryhma') }}
    where valtioryhma_koodiarvo in ('EU', 'ETA')
),

kansalaisuus_riveille as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'henkilo_oid']
            ) }} as henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        muokattu,
        dw_metadata_dbt_copied_at,
        (jsonb_array_elements(kansalaisuus) ->> 0) as kansalaisuus --noqa: CV11
    from hakemukset
),

kansalaisuus_jarjestys as (
    select
        henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        case
            when kansalaisuus = '246' then 1
            when kansalaisuus in (
                select maa_koodiarvo from maa_valtioryhma
            ) then 2
            else 3
        end
        as jarjestys,
        muokattu,
        dw_metadata_dbt_copied_at
    from kansalaisuus_riveille
),

haluttu_kansalaisuus as (
    select
        henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        row_number() over (partition by henkilotieto_id order by jarjestys) as haluttu_kansalaisuus,
        muokattu,
        dw_metadata_dbt_copied_at
    from kansalaisuus_jarjestys
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['henkilotieto_id',
            'haluttu_kansalaisuus']
         ) }} as henkilotieto_kansalaisuus_id,
        *
    from haluttu_kansalaisuus
)

select * from final
