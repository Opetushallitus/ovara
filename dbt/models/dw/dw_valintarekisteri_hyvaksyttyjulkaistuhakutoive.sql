{%- set stage_model = ref('stg_valintarekisteri_hyvaksyttyjulkaistuhakutoive') -%}
{%- set key_columns_list = ['hakukohde_henkilo_id','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
