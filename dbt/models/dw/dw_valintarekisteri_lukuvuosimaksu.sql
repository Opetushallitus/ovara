{% set src_model = ref('stg_valintarekisteri_lukuvuosimaksu') %}
{% set key_columns_list = ['hakukohde_henkilo_id','muokattu'] %}

{{ generate_dw_model_muokattu(src_model,key_columns_list) }}
