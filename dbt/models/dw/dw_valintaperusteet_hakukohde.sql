{%- set stage_model = ref('stg_valintaperusteet_hakukohde') -%}
{%- set key_columns_list = ['hakukohde_oid','muokattu'] -%}

{{ generate_dw_model_muokattu(stage_model, key_columns_list) }}
