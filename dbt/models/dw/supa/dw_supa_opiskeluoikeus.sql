{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    pre_hook = [
        """{% if is_incremental() %}
            delete from {{ this }} as t
            using
            (
                select henkilo_oid
                from {{ ref('stg_supa_opiskeluoikeus') }}
                where dw_metadata_stg_stored_at > (select max (dw_metadata_stg_stored_at) from {{ this }})
            )
            as s where t.henkilo_oid=s.henkilo_oid;
            {% endif %}
        """
        ],
    indexes = [
        {'columns': ['dw_metadata_stg_stored_at','henkilo_oid']}
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