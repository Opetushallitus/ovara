{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['versioitu_koodiuri']}
    ]
    )
}}
with koodisto as (
    select * from {{ ref('int_koodisto_koodi') }}
)

select
    versioitu_koodiuri,
    koodistouri,
    koodiuri,
    koodiarvo,
    koodiversio,
    nimi_fi,
    nimi_sv,
    nimi_en,
    tila,
    voimassaalkupvm,
    voimassaloppupvm
from koodisto
