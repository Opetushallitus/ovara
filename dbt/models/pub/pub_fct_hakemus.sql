{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['haku_oid']},
        {'columns':['henkilo_oid']},
        {'columns':['hakemus_oid']}

    ]
    )
}}

with hakemus as not materialized (
    select * from {{ ref('int_ataru_hakemus') }}
    where not tila = 'inactivated'
),

int as (
    select
        hake.hakemus_oid,
        hake.haku_oid,
        hake.tila,
        hake.henkilo_oid
    from hakemus as hake

)

select * from int
order by haku_oid
