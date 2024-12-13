{{
  config(
    materialized = 'table',
    indexes = [
    {'columns':['organisaatio_oid']}
    ]
    )
}}

with source as (
    select * from  {{ ref('int_organisaatio') }}
),

final as (
    select
        organisaatio_oid,
        organisaatio_nimi,
        sijaintikunta,
        sijaintikunta_nimi,
        opetuskielet,
        organisaatiotyypit,
        tila,
        oppilaitostyyppi,
        oppilaitosnumero,
        alkupvm,
        lakkautuspvm
    from source
)

select * from final