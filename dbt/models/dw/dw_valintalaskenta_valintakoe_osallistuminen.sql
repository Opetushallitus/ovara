{%- set stage_model = ref('stg_valintalaskenta_valintakoe_osallistuminen') -%}
{%- set key_columns_list = ['hakemusOid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}