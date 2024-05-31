{{
  config(
    indexes = [
        {'columns': ['muokattu']},
    ],
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'hakutoive_id',
    pre_hook =
                """
                {% if is_incremental() %}
                update {{this}}
                set poistettu=true::boolean
                where hakemus_oid in (
                    select distinct oid from {{ ref('int_ataru_hakemus') }}
                    where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
                )
                {%- endif -%}
                """
    )
}}

with raw as (
    select
        oid,
        hakukohde,
        muokattu,
        dw_metadata_dbt_copied_at
    from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

latest_hakemus as (
    select
        oid,
        hakukohde,
        muokattu,
        dw_metadata_dbt_copied_at
    from raw
),

hakutoive_raw as (
    select
        oid as hakemus_oid,
        muokattu,
        dw_metadata_dbt_copied_at,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid
    from latest_hakemus
),

hakutoivenro as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'hakukohde_oid']
        ) }} as hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        muokattu,
        dw_metadata_dbt_copied_at,
        row_number() over (partition by hakemus_oid) as hakutoivenumero
    from hakutoive_raw
),

final as (
    select
        hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        hakutoivenumero,
        false::boolean as poistettu,
        muokattu,
        dw_metadata_dbt_copied_at
    from hakutoivenro
)

select * from final
