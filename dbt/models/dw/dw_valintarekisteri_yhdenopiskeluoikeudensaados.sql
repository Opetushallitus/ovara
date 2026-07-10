{%- set stage_model = ref('stg_valintarekisteri_yhdenopiskeluoikeudensaados') -%}
{%- set key_columns_list = ['hakutoive_id','muokattu'] -%}


{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
