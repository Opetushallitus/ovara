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
        koul.koulutus_oid,
        koul.koulutus_nimi,
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
        lyks.koodinimi as laajuusyksikko_nimi
    from koulutus as koul
    left join opintojenlaajuusyksikko as lyks on koul.opintojenlaajuusyksikkokoodiuri = lyks.versioitu_koodiuri
)

select * from data
