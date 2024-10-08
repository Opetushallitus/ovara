{%- set stage_model = ref('stg_koodisto_relaatio') -%}
{%- set key_columns_list = ['koodirelaatio_id'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
