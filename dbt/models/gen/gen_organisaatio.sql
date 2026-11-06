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
),

oppilaitos as (
    select * from {{ ref('int_organisaatio_hakukohteiden_nimet') }}
)

select
    org.organisaatio_oid,
    org.nimi_fi,
    org.nimi_sv,
    coalesce(org.nimi_fi, org.nimi_sv) as nimi_en,
    org.alkupvm,
    org.lakkautuspvm,
    org.tila,
    org.ylempi_organisaatio,
    org.ylin_organisaatio,
    org.organisaatiotyypit,
    org.sijaintikunta,
    org.opetuskielet,
    org.oppilaitostyyppi,
    org.oppilaitosnumero,
    opla.oppilaitos_nimi,
    opla.oppilaitos as oppilaitos_oid,
    opla.oppilaitos_nimi ->> 'fi' as oppilaitos_nimi_fi,
    opla.oppilaitos_nimi ->> 'sv' as oppilaitos_nimi_sv,
    opla.oppilaitos_nimi ->> 'en' as oppilaitos_nimi_en,
    opla.toimipiste_nimi,
    opla.toimipiste as toimipiste_oid,
    opla.toimipiste_nimi ->> 'fi' as toimipiste_nimi_fi,
    opla.toimipiste_nimi ->> 'sv' as toimipiste_nimi_sv,
    opla.toimipiste_nimi ->> 'en' as toimipiste_nimi_en
from org
left join oppilaitos as opla on org.organisaatio_oid = opla.jarjestyspaikka_oid
