{{
  config(
    indexes = [
        {'columns': ['henkilo_oid']}
    ],
    )
}}

{%- set stage_model = ref('stg_onr_henkilo') -%}
{%- set key_columns_list = ['henkilo_oid'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows