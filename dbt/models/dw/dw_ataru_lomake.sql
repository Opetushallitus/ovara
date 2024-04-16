{{
  config(
    indexes = [{'columns':['id','versio_id','muokattu']}]
    )
}}


{%- set stage_model = ref('stg_ataru_lomake') -%}
{%- set key_columns_list = ['id','versio_id'] -%}

with current_rows as (
    {{ generate_dw_model(stage_model, key_columns_list) }}
)

select * from current_rows