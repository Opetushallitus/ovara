{%- set stage_model = ref('stg_sure_opiskeluoikeus') -%}
{%- set key_columns_list = ['resourceid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
