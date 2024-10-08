{%- set stage_model = ref('stg_valintalaskenta_valintalaskennan_tulos') -%}
{%- set key_columns_list = ['valinnanvaihe_id','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
