 {% set src_model = ref('stg_valintarekisteri_valintatapajono') %}
 {% set key_columns_list = ['valintatapajono_id'] %}

 {{ generate_dw_model_muokattu(src_model,key_columns_list) }}

 select * from final
