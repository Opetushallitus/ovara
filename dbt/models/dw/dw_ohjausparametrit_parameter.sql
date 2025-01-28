{% set src_model = ref('stg_ohjausparametrit_parameter') %}
{% set key_columns_list = ['haku_oid','muokattu'] %}

{{ generate_dw_model_muokattu(src_model,key_columns_list) }}
