{{
  config(
    indexes = [{'columns':['resourceid','muokattu']}]
    )
}}

{%- set stage_model = ref('stg_sure_opiskeluoikeus') -%}
{%- set key_columns_list = ['resourceid','muokattu'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows