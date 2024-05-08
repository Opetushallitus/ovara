{{
  config(
    indexes = [{"columns":['oid','versio_id','muokattu']}]
    )
}}


{%- set stage_model = ref('stg_ataru_hakemus') -%}
{%- set key_columns_list = ['oid','versio_id','muokattu'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows