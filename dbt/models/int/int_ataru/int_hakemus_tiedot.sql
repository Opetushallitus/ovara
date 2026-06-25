{{
  config(
    materialized = 'incremental',
    incremental_strategy= 'delete+insert',
    unique_key = 'hakemus_oid',
    unlogged=true,
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']}
    ],
    pre_hook = [
        "set enable_seqscan = off;",
        """{% if is_incremental() %}
            with changed as materialized (
                select distinct hakemus_oid
                from {{ref('int_ataru_hakemus') }}
                where dw_metadata_dw_stored_at >
                (
                    select max(dw_metadata_dw_stored_at)
                    from {{ this }}
                )
            )
            delete from {{ this }} t
            using changed s
            where t.hakemus_oid = s.hakemus_oid;
            {% endif %}
        """
    ],
    post_hook = [
        "set enable_seqscan = on;",
        "create unique index if not exists int_hakemus_tiedot_hakemus_oid_kysymys_pk on {{ this }} (hakemus_oid, kysymys);"
        ]
    )
}}
with source as (
    select
        hakemus_oid,
        tiedot,
        dw_metadata_dw_stored_at
    from {{ ref('int_ataru_hakemus') }}
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

select
    hakemus_oid,
    rivi.key as kysymys,
    rivi.value as vastaus,
    hake.dw_metadata_dw_stored_at
from source as hake
cross join lateral jsonb_each(hake.tiedot) as rivi (key, value)
