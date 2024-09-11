{%- set stage_model = ref('stg_organisaatio_organisaatio') -%}
{%- set key_columns_list = ['organisaatio_oid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
