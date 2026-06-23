{{
  config(
    materialized = 'incremental',
    incremental_strategy= 'append',
    unlogged=true,
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']}
    ],
    pre_hook = ["set enable_seqscan = off;",
                """{% if is_incremental() %}
            delete from {{ this }} as t
            using
            (
                select distinct hakemus_oid
                from {{ ref('int_supa_valintadata') }}
                where dw_metadata_dw_stored_at > (select max (dw_metadata_dw_stored_at) from {{ this }})
            )
            as s where t.hakemus_oid=s.hakemus_oid;
            {% endif %}
            """
        ],
    post_hook = "set enable_seqscan = on;"
    )
}}
with source as (
    select
        hakemus_oid,
        keyvalues,
        dw_metadata_dw_stored_at
    from {{ ref('int_supa_valintadata') }}
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
    rivi.key as avain,
    rivi.value as arvo,
    vada.dw_metadata_dw_stored_at
from source as vada
cross join lateral jsonb_each(vada.keyvalues) as rivi (key, value)
