{% set src_model = ref('stg_valintarekisteri_vastaanotto') %}
{% set key_columns_list = ['vastaanotto_id','muokattu'] %}

{{ generate_dw_model_muokattu(src_model,key_columns_list) }}

select * from final
