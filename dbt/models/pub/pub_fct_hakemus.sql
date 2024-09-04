{{
  config(
    materialized = 'table'
    )
}}

with hakemus as (
    select * from {{ ref('int_ataru_hakemus') }}
    where not tila = 'inactivated'
),

int as (
    select
        hakemus_oid,
        haku_oid,
        tila,
        coalesce(valintatuloksen_julkaisulupa, false) as julkaisulupa,
        coalesce(koulutusmarkkinointilupa, false) as koulutusmarkkinointilupa,
        henkilo_oid
    from hakemus
)

select * from int
