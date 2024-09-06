{#
    Todo: koulutuksen alku ja hakukausi + -vuosi puuttuvat vielä. Selvityksessä mistä tämä tieto saadaan
#}

{{
    config(
        materialized = 'table'
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
        raw1.haku_oid,
        raw1.haku_nimi,
        raw1.externalid,
        raw1.tila,
        raw1.hakutapakoodiuri,
        hata.koodiarvo as hakutapa_koodi,
        hata.koodinimi as hakutapa_nimi,
        raw1.kohdejoukkokoodiuri,
        hajo.koodiarvo as kohdejoukko_koodi,
        hajo.koodinimi as kohdejoukko_nimi,
        raw1.kohdejoukontarkennekoodiuri,
        hatr.koodiarvo as kohdejoukontarkenne_koodi,
        hatr.koodinimi as kohdejoukontarkenne_nimi
    from raw as raw1
    inner join hakutapakoodi as hata on raw1.hakutapakoodiuri = hata.versioitu_koodiuri
    inner join haunkohdejoukko as hajo on raw1.kohdejoukkokoodiuri = hajo.versioitu_koodiuri
    left join haunkohdejoukontarkenne as hatr on raw1.kohdejoukontarkennekoodiuri = hatr.versioitu_koodiuri
),

final as (
    select * from step1
)

select * from final
