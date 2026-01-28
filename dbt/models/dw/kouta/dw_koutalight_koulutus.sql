{%- set stage_model = ref('stg_koutalight_koulutus') -%}
{%- set key_columns_list = ['koulutus_id','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
