{%- set stage_model = ref('stg_kouta_asiasana') -%}
{%- set key_columns_list = ['kieli','arvo'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
