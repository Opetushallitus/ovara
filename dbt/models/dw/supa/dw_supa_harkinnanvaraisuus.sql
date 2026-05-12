{%- set stage_model = ref('stg_supa_harkinnanvaraisuus') -%}
{%- set key_columns_list = ['hakemus_oid'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
