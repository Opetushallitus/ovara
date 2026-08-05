{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'distinct_delete+insert',
    unique_key = 'henkilo_oid',
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['dw_metadata_dw_stored_at']}
    ],
    pre_hook = ["SET LOCAL enable_mergejoin = off;"]
    post_hook = [
        "{{ create_pk('henkilo_oid') }}",
        "create index if not exists ix_supa_opiskeluoikeus_yo on {{ this }} (henkilo_oid) where jsonb_array_length(data -> 'yoOpiskeluoikeudet') > 0;",
        "create index if not exists ix_supa_opiskeluoikeus_kk on {{ this }} (dw_metadata_dw_stored_at, henkilo_oid) where jsonb_array_length(data -> 'kkOpiskeluoikeudet') > 0;"
        ]
    )
}}

with source as (
    select * from {{ ref('dw_supa_opiskeluoikeus') }}
    {% if is_incremental() %}
      where dw_metadata_stg_stored_at > coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
)

select
    {{ dbt_utils.star(from=ref('dw_supa_opiskeluoikeus'), except=['data']) }},
    data::jsonb
from source
