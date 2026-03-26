{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['organisaatio_oid']}
    ]
    )
}}

with org as (
    select * from {{ ref('int_organisaatio_organisaatio') }}
)

select
    organisaatio_oid,
    nimi_fi,
    nimi_sv,
    alkupvm,
    lakkautuspvm,
    tila,
    ylempi_organisaatio,
    ylin_organisaatio,
    organisaatiotyypit,
    sijaintikunta,
    opetuskielet,
    oppilaitostyyppi,
    oppilaitosnumero
from org
