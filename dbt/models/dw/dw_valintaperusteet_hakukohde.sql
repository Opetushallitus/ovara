{%- set src_model = ref('stg_valintaperusteet_hakukohde') -%}
{%- set key_columns_list = ['valinnanvaihe_id','muokattu'] -%}

{{ generate_dw_model_muokattu(src_model, key_columns_list) }}

select * from final

