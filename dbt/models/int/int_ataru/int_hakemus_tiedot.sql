{{
  config(
    materialized = 'incremental',
    incremental_strategy= 'delete+insert',
    unique_key = 'hakemus_oid',
    unlogged=true,
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']}
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
    where dw_metadata_dw_stored_at >= coalesce(
            (select max(dw_metadata_dw_stored_at) from {{ this }}),
            '1900-01-01'::timestamptz
        )
    {% endif %}
)

select
	hakemus_oid,
	e.key as kysymys,
	e.value as vastaus,
    dw_metadata_dw_stored_at
from source as hake
cross join lateral jsonb_each(hake.tiedot) as e(key,value)
