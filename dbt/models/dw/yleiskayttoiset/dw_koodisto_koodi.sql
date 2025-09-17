{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['koodistouri']},
    ]
    )
}}

with raw as (
    select * from {{ ref('stg_koodisto_koodi') }}
),

final as (
    select
        *,
        current_timestamp as dw_metadata_dw_stored_at
    from raw
)

select * from final
