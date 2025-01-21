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
        hake.henkilo_oid,
        case
            when hake.keyvalues -> '4fe08958-c0b7-4847-8826-e42503caa662' is not null or
            hake.keyvalues -> '32b8440f-d6f0-4a8b-8f67-873344cc3488' is not null or
            hake.keyvalues -> 'kaksoistutkinto-lukio' is not null or
            hake.keyvalues -> 'kaksoistutkinto-amm' is not null
            then true::boolean else false::boolean
        end as kaksoistutkinto_kiinnostaa,
        case
            when hake.keyvalues -> '1dc3311d-2235-40d6-88d2-de2bd63e087b' is not null
            then true::boolean else false::boolean
        end as tutkinto_urheilijana_kiinnostaa
    from hakemus as hake

)

select * from int
order by haku_oid
