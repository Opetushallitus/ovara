{%- set stage_model = ref('stg_koodisto_koodi') -%}
{%- set key_columns_list = ['koodi_id'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
