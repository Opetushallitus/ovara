{%- set stage_model = ref('stg_onr_yhteystieto') -%}
{%- set key_columns_list = ['yhteystieto_id'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
