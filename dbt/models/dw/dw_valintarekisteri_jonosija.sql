{% set src_model = ref('stg_valintarekisteri_jonosija') %}
{% set key_columns_list = ['id','muokattu'] %}

{{ generate_dw_model_muokattu(src_model,key_columns_list) }}
