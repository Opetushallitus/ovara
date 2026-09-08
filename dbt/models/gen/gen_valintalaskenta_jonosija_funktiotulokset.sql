{{
  config(
    materialized = 'incremental',
    unique_key= 'valinnanvaihe_id',
    incremental_strategy = 'distinct_delete+insert',
    indexes = [
        {'columns': ['hakemus_oid']},
        {'columns': ['hakija_oid']},
        {'columns': ['dw_metadata_dw_stored_at']},
        {'columns': ['valinnanvaihe_id']}
    ]
    )
}}

with
{% if is_incremental() %}

max_stored_at as (
    select
        coalesce(
            max(dw_metadata_dw_stored_at),
            timestamptz '1900-01-01 00:00:00+00'
        ) as max_date
    from {{ this }}
),
{% endif %}

source as (
    select funk.* from {{ ref('int_valintalaskenta_jonosija_funktiotulokset') }} as funk
    {% if is_incremental() %}
    cross join max_stored_at as mxdt
    where funk.dw_metadata_dw_stored_at > mxdt.max_date
    {% endif %}
)

select * from source
