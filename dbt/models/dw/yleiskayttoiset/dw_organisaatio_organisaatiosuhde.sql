{%- set stage_model = ref('stg_organisaatio_organisaatiosuhde') -%}
{%- set key_columns_list = ['suhde_id'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
