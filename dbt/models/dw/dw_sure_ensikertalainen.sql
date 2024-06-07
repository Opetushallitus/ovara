{{
  config(
    indexes = [{'columns':['hakuoid','henkilooid']}]
    )
}}

{%- set stage_model = ref('stg_sure_ensikertalainen') -%}
{%- set key_columns_list = ['hakuoid','henkilooid'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows