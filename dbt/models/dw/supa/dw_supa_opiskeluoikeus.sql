{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'delete+insert',
    unique_key = 'henkilo_oid',
    indexes = [
        {'columns': ['dw_metadata_stg_stored_at','henkilo_oid']},
        {'columns':['henkilo_oid']}
    ]

    )
}}

with source as (
    select distinct on (henkilo_oid) *
    from {{ ref('stg_supa_opiskeluoikeus') }}
    {% if is_incremental() %}
      where dw_metadata_stg_stored_at > coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
    order by henkilo_oid, aikaleima desc
)

select
    *,
    current_timestamp as dw_metadata_dw_stored_at
from source