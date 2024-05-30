{%- set stage_model = ref('stg_kouta_koulutus') -%}
{%- set key_columns_list = ['oid','muokattu'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows
