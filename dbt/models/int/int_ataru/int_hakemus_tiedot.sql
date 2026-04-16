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
    pre_hook = "set enable_seqscan = off;",
    post_hook = "set enable_seqscan = on;"
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
