{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']}
        ]
    )
}}

with hakemus as (
    select * from {{ ref('int_ataru_hakemus') }}
    where kasittelymerkinnat is not null
),

final as (
    select
        hake.hakemus_oid,
        kame.hakukohde as hakukohde_oid,
        kame.requirement,
        kame.state
    from hakemus as hake
    cross join lateral jsonb_to_recordset(hake.kasittelymerkinnat) as kame(
        state text,
        hakukohde text,
        requirement text
    )
)

select
    {{ hakutoive_id() }},
    *
from final
