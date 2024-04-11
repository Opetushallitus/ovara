{{
  config(
    indexes = [{'columns':['id','muokattu']}]
    )
}}

{%- set stage_model = ref('stg_kouta_pistehistoria') -%}
{%- set key_columns_list = ['id'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows