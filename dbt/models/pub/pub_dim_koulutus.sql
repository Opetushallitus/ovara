{{
  config(
    materialized = 'table',
    indexes = [
    ]
    )
}}

with koulutus as (
    select
        *,
        koulutuksetkoodiuri ->> 0 as koulutus_koodi
    from {{ ref('int_kouta_koulutus') }}
),

opintojenlaajuusyksikko as (
    select * from {{ ref('int_koodisto_opintojenlaajuusyksikko') }}
),

koulutus_alat_ja_asteet as (
    select * from {{ ref ('int_koodisto_koulutus_alat_ja_asteet') }}
),

koulutustiedot as (
    select
        koul.koulutus_oid,
        case when sum(kaja.alempi_kk_aste) > 0 then 1::bool else 0::bool end as alempi_kk_aste,
        case when sum(kaja.ylempi_kk_aste) > 0 then 1::bool else 0::bool end as ylempi_kk_aste
    from koulutus as koul
    cross join lateral jsonb_array_elements_text(koul.koulutuksetkoodiuri) as e (rivikoodiuri)
    inner join koulutus_alat_ja_asteet as kaja on e.rivikoodiuri = kaja.versioitu_koodiuri
    group by koulutus_oid
),

final as (
    select
        koul.koulutus_oid,
        koul.koulutus_nimi,
        koul.externalid as ulkoinen_tunniste,
        koul.tila,
        koul.organisaatio_oid,
        koul.koulutustyyppi,
        koul.tarjoajat,
        koul.kielivalinta,
        coalesce(
            koul.opintojenlaajuusnumero::text,
            koul.opintojenlaajuusnumeromin::text || '-' || koul.opintojenlaajuusnumeromax::text
        ) as opintojenlaajuus,
        lyks.koodinimi as laajuusyksikko_nimi,
        koul.koulutuksetkoodiuri as koulutus_koodit,
        coalesce(koti.alempi_kk_aste, false) as alempi_kk_aste,
        coalesce(koti.ylempi_kk_aste, false) as ylempi_kk_aste,
        koul.koulutus_koodi,
        kala.okm_ohjauksen_ala,
        kala.kansallinenkoulutusluokitus2016koulutusastetaso1,
        kala.kansallinenkoulutusluokitus2016koulutusastetaso2,
        kala.kansallinenkoulutusluokitus2016koulutusalataso1,
        kala.kansallinenkoulutusluokitus2016koulutusalataso2,
        kala.kansallinenkoulutusluokitus2016koulutusalataso3,
        kala.jatkotutkinto,
        kala.laakis,
        case
            when koti.alempi_kk_aste and not koti.ylempi_kk_aste then 1
            when not koti.alempi_kk_aste and koti.ylempi_kk_aste then 2
            when koti.alempi_kk_aste and koti.ylempi_kk_aste then 3
            when kala.jatkotutkinto then 4
            else 5
        end as kk_tutkinnon_taso
    from koulutus as koul
    left join opintojenlaajuusyksikko as lyks
        on koul.opintojenlaajuusyksikkokoodiuri = lyks.versioitu_koodiuri
    left join koulutustiedot as koti
        on koul.koulutus_oid = koti.koulutus_oid
    left join koulutus_alat_ja_asteet as kala
        on koul.koulutus_koodi = kala.versioitu_koodiuri
)

select * from final
