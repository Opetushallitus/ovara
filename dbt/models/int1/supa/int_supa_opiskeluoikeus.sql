{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    indexes = [
        {'columns': ['henkilo_oid']}
    ],
    pre_hook = [
        """{% if is_incremental() %}
            with changed as materialized (
                select distinct henkilo_oid
                from {{ref('dw_supa_opiskeluoikeus') }}
                where dw_metadata_stg_stored_at >
                (
                    select max(dw_metadata_stg_stored_at)
                    from {{ this }}
                )
            )
            delete from {{ this }} t
            using changed s
            where t.henkilo_oid = s.henkilo_oid;
            {% endif %}
        """
        ],
    post_hook = [
        "{{ create_pk('henkilo_oid') }}",
        "create index if not exists ix_supa_opiskeluoikeus_yo on {{ this }} (henkilo_oid) where jsonb_array_length(data -> 'yoOpiskeluoikeudet') > 0;"
        ]
    )
}}

with source as (
    select distinct on (henkilo_oid) *
    from {{ ref('dw_supa_opiskeluoikeus') }}
    {% if is_incremental() %}
      where dw_metadata_stg_stored_at > coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
    order by henkilo_oid, aikaleima desc
)

select
    {{ dbt_utils.star(from=ref('dw_supa_opiskeluoikeus'), except=['data']) }},
    data::jsonb
from source
