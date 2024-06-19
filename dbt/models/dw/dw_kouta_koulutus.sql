 {% set src_model = ref('stg_kouta_koulutus') %}
 {% set key_columns_list = ['oid','muokattu'] %}



 {{ generate_dw_model_muokattu(src_model,key_columns_list) }}


 select * from final
