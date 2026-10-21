{{
  config(
    materialized = 'table',
    indexes = [
        {"columns": ["henkilo_oid"]}
        ]
    )
}}
with kk as (
    select * from {{ ref('int_supa_suoritus_kk') }}
),

yo as (
    select * from {{ ref('int_supa_suoritus_yo') }}
),

perus as (
    select * from  {{ ref('int_supa_suoritus_perus') }}
),

final as (
    select
        henkilo_oid,
        tunniste,
        tyyppi,
        lahdejarjestelma,
        tila,
        lahdejarjestelman_tila,
        alku_pvm,
        paattymis_pvm,
        suorituskieli,
        null as koulusivistyskieli,
        null as yksilollistaminen
    from kk

    union all

    select
        henkilo_oid,
        tunniste,
        tyyppi,
        lahdejarjestelma,
        tila,
        null as lahdejarjestelman_tila,
        null as alku_pvm,
        paattymis_pvm,
        suorituskieli,
        null as koulusivistyskieli,
        null as yksilollistaminen
    from yo

    union all

    select
        henkilo_oid,
        tunniste,
        tyyppi,
        lahdejarjestelma,
        tila,
        lahdejarjestelman_tila,
        alku_pvm,
        paattymis_pvm,
        suorituskieli,
        koulusivistyskieli,
        yksilollistaminen
    from perus
)

select * from final
