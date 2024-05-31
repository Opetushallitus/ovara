{{
  config(
    indexes = [
    ],
    )
}}

{%- set stage_model = ref('stg_hakukohderyhmapalvelu_ryhma') -%}
{%- set key_columns_list = ['oid'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows
