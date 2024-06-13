{{
  config(
    indexes = [
        {'columns':['valintakoe_hakemus_id','muokattu']}
    ]
    )
}}

{%- set stage_model = ref('stg_valintapiste_service_pistetieto') -%}
{%- set key_columns_list = ['valintakoe_hakemus_id','muokattu'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows
