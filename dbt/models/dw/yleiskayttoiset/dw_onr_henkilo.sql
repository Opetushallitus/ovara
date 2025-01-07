{#
{%- set stage_model = ref('stg_onr_henkilo') -%}
{%- set key_columns_list = ['henkilo_oid'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}

#}

{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid']}
    ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by henkilo_oid order by dw_metadata_stg_stored_at desc) as rownr
        from {{ ref('stg_onr_henkilo') }}
),

final as (
    select
        {{ dbt_utils.star(from=ref('stg_onr_henkilo')) }},
        current_timestamp as dw_metadata_dw_stored_at
    from raw
    where rownr =1
)

select * from final


