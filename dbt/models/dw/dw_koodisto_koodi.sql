{%- set model='stg_koodisto_koodi'-%}
{%- set columns = adapter.get_columns_in_relation(ref(model)) -%}

{{
  config(
    indexes =[
      {'columns':['id','muokattu']},
      {'columns':['dw_metadata_dbt_copied_at']},
      {'columns':['koodiuri','koodiversio']}
      ],
    materialized= 'incremental',
    incremental_strategy = 'merge',
    unique_key='id',
    merge_exclude_columns = [
        'dw_metadata_source_timestamp_at',
        'dw_metadata_stg_stored_at',
        'dw_metadata_dbt_copied_at',
        'dw_metadata_filename',
        'dw_metadata_file_row_number',
        'dw_metadata_timestamp',
        'dw_metadata_dw_stored_at'],    
    )
}}

with 
raw as (
    select 
    *
    from {{ ref(model) }}

    {% if is_incremental() %}
      where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})



    {% endif %}
),

int as (
  select 
  *, 
  row_number() over (partition by id order by dw_metadata_dbt_copied_at desc) as _row_nr,
  coalesce(dw_metadata_source_timestamp_at, dw_metadata_dbt_copied_at) as dw_metadata_timestamp,
  current_timestamp as dw_metadata_dw_stored_at
  from raw
 ),

final as(
  select

    {%- for col in columns %}
        {{ col.column }}
        {%- if not loop.last -%}
        ,
        {%- endif -%}
    {% endfor %},
  dw_metadata_timestamp,
  dw_metadata_dw_stored_at
  from int
  where _row_nr =1
)

select * from final
