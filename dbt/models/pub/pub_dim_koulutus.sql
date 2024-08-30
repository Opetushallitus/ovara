{{
  config(
    materialized = 'table',
    indexes = [
    ]
    )
}}

with koulutus as (
    select * from {{ ref('int_kouta_koulutus') }}
),

opintojenlaajuusyksikko as (
    select * from {{ ref('int_koodisto_opintojenlaajuusyksikko') }}
),

data as (
    select
        koul.oid,
        koul.nimi_fi,
        koul.nimi_sv,
        koul.nimi_en,
        koul.organisaatio_oid,
        koul.externalid,
        koul.koulutustyyppi,
        koul.tila,
        koul.tarjoajat,
        koul.kielivalinta,
        coalesce(
            koul.opintojenlaajuusnumero::text,
            koul.opintojenlaajuusnumeromin::text || '-' || koul.opintojenlaajuusnumeromax::text
        ) as opintojenlaajuus,
        lyks.nimi_fi as laajuusyksikko_nimi_fi,
        lyks.nimi_sv as laajuusyksikko_nimi_sv,
        lyks.nimi_en as laajuusyksikko_nimi_en
    from koulutus as koul
    left join opintojenlaajuusyksikko as lyks on koul.opintojenlaajuusyksikkokoodiuri = lyks.versioitu_koodiuri
)

select * from data
