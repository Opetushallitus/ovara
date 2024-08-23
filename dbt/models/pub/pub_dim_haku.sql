{#
    Todo: koulutuksen alku ja hakukausi + -vuosi puuttuvat vielä. Selvityksessä mistä tämä tieto saadaan
#}

{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('int_kouta_haku') }}
),

hakutapakoodi as (
    select * from {{ ref('pub_dim_koodisto_hakutapa') }}
),

haunkohdejoukko as (
    select * from {{ ref('pub_dim_koodisto_haunkohdejoukko') }}
),

haunkohdejoukontarkenne as (
    select * from {{ ref('pub_dim_koodisto_haunkohdejoukontarkenne') }}
),

step1 as (
    select
        raw1.oid,
        raw1.nimi_fi,
        raw1.nimi_sv,
        raw1.nimi_en,
        raw1.externalid,
        raw1.tila,
        raw1.hakutapakoodiuri,
        hata.nimi_fi as hakutapa_nimi_fi,
        hata.nimi_sv as hakutapa_nimi_sv,
        hata.nimi_en as hakutapa_nimi_en,
        raw1.kohdejoukkokoodiuri,
        hajo.nimi_fi as kohdejoukko_nimi_fi,
        hajo.nimi_sv as kohdejoukko_nimi_sv,
        hajo.nimi_en as kohdejoukko_nimi_en,
        raw1.kohdejoukontarkennekoodiuri,
        hatr.nimi_fi as kohdejoukontarkenne_nimi_fi,
        hatr.nimi_sv as kohdejoukontarkenne_nimi_sv,
        hatr.nimi_en as kohdejoukontarkenne_nimi_en
    from raw as raw1
    inner join hakutapakoodi as hata on raw1.hakutapakoodiuri = hata.versioitu_koodiuri
    inner join haunkohdejoukko as hajo on raw1.kohdejoukkokoodiuri = hajo.versioitu_koodiuri
    left join haunkohdejoukontarkenne as hatr on raw1.kohdejoukontarkennekoodiuri = hatr.versioitu_koodiuri
),

final as (
    select * from step1
)

select * from final
