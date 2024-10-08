{%- set stage_model = ref('stg_kouta_toteutus') -%}
{%- set key_columns_list = ['oid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
