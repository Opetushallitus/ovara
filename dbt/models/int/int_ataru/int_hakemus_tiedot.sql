{{
  config(
    materialized = 'table',
    unlogged=true,
    post_hook=[
        "{{ disable_autovacuum_if_not_incremental() }}"
    ]
    )
}}
with source as not materialized (
    select
        hakemus_oid,
        tiedot
    from {{ ref('int_ataru_hakemus') }}
)

select
	hakemus_oid,
	e.key as kysymys,
	e.value as vastaus
from source as hake
cross join lateral jsonb_each(hake.tiedot) as e(key,value)
