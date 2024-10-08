{%- set stage_model = ref('stg_organisaatio_ryhma') -%}
{%- set key_columns_list = ['oid'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
