{%- set stage_model = ref('stg_valintapiste_service_pistetieto') -%}
{%- set key_columns_list = ['valintakoe_hakemus_id','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
