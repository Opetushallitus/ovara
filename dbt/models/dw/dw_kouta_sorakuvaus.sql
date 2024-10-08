{%- set stage_model = ref('stg_kouta_sorakuvaus') -%}
{%- set key_columns_list = ['id','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
