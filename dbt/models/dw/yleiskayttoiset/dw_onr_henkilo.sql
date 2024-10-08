{%- set stage_model = ref('stg_onr_henkilo') -%}
{%- set key_columns_list = ['henkilo_oid'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
