{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['haku_oid']}
    ]
    )
}}

with hakemus as (
    select * from {{ ref('int_ataru_hakemus') }}
    where not tila = 'inactivated'
),

int as (
    select
        hake.hakemus_oid,
        hake.haku_oid,
        hake.tila,
        coalesce(hake.valintatuloksen_julkaisulupa, false) as julkaisulupa,
        coalesce(hake.koulutusmarkkinointilupa, false) as koulutusmarkkinointilupa,
        coalesce(hake.sahkoinenviestintalupa, false) as sahkoinenviestintalupa,
        hake.henkilo_oid
    from hakemus as hake

)

select * from int
order by haku_oid
