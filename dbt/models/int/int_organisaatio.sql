{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['organisaatio_oid','tila']},
        {'columns':['tila']},
    ]
    )
}}

with source as (
    select * from {{ ref('dw_organisaatio_organisaatio') }}
),

final as (
    select
        organisaatio_oid,
        tila,
        nimi_fi,
        nimi_sv,
        muokattu
    from source
)

select * from final
