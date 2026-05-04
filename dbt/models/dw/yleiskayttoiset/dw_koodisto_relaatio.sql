{{
  config(
    materialized = 'table',
    unlogged = true,
    indexes = [
        {'columns': ['koodirelaatio_id']},
    ]
    )
}}

with raw as (
    select * from {{ ref('stg_koodisto_relaatio') }}
),

final as (
    select
        *,
        current_timestamp as dw_metadata_dw_stored_at
    from raw
)

select * from final
