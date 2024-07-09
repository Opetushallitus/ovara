{%- set stage_model = ref('stg_sure_opiskelija') -%}
{%- set key_columns_list = ['resourceid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
