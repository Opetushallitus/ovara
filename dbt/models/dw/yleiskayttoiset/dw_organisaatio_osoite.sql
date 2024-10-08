{%- set stage_model = ref('stg_organisaatio_osoite') -%}
{%- set key_columns_list = ['organisaatioosoite_id'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
