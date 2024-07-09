{%- set stage_model = ref('stg_sure_ensikertalainen') -%}
{%- set key_columns_list = ['hakuoid','henkilooid'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
