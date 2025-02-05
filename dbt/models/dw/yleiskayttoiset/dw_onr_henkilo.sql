{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'henkilo_oid',
    merge_exclude_columns = [
            'dw_metadata_dbt_copied_at',
            'dw_metadata_file_row_number',
            'dw_metadata_filename',
            'dw_metadata_source_timestamp_at',
            'dw_metadata_dw_stored_at'
            ],
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['muokattu']}
    ]
    )
}}

with raw as (
    select * from {{ ref('stg_onr_henkilo') }}
    {% if is_incremental() %}
      where muokattu > (select coalesce(max(t.muokattu),date('1900-01-01'))  from {{this}} as t )
    {% endif %}
),

final as (
    select
        *,
        current_timestamp as dw_metadata_dw_stored_at
    from raw
)


select * from final
