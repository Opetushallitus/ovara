{% set src_model = ref('stg_valintarekisteri_ilmoittautuminen') %}
{% set key_columns_list = ['ilmoittautuminen_id','muokattu'] %}

{{ generate_dw_model_muokattu(src_model,key_columns_list) }}
