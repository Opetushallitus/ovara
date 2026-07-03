{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['tila']}
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
    coalesce(nimi_fi, nimi_sv) as nimi_en,
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
