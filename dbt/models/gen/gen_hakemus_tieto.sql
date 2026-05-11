{{
    config(
    materialized = 'incremental',
    incremental_strategy= 'delete+insert',
    unique_key = 'hakemus_oid',
    unlogged=true,
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']},
        {'columns':['kysymys']}
    ]
    )
}}

with source as not materialized (
    select * from {{ ref('int_hakemus_tiedot') }}
    {% if is_incremental() %}
        where dw_metadata_dw_stored_at >= (
            select
                coalesce(
                    max(dw_metadata_dw_stored_at),
                    '1900-01-01'::timestamptz
                )
            from {{ this }}
        )
    {% endif %}
)

select * from source
