{{
  config(
    indexes = [{'columns':['hakemusOid','muokattu']}]
    )
}}

{%- set stage_model = ref('stg_valintalaskenta_valintakoe_osallistuminen') -%}
{%- set key_columns_list = ['hakemusOid','muokattu'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows
