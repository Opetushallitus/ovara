{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['koulutuksen_alkamiskausi'],
            "type": "gin"}
        ]
    )
}}

with haku as (
    select * from {{ ref('int_haku') }}
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
        haku.haku_oid,
        haku.haku_nimi,
        ulkoinen_tunniste,
        haku.tila,
        haku.hakutapakoodiuri,
        haku.hakuajat,
        hata.koodiarvo as hakutapa_koodi,
        hata.koodinimi as hakutapa_nimi,
        haku.kohdejoukkokoodiuri,
        hajo.koodiarvo as kohdejoukko_koodi,
        hajo.koodinimi as kohdejoukko_nimi,
        haku.kohdejoukontarkennekoodiuri,
        hatr.koodiarvo as kohdejoukontarkenne_koodi,
        hatr.koodinimi as kohdejoukontarkenne_nimi,
        haku.koulutuksen_alkamiskausi_yhd as koulutuksen_alkamiskausi,
        haku.haun_tyyppi
    from haku as haku
    inner join hakutapakoodi as hata on haku.hakutapakoodiuri = hata.versioitu_koodiuri
    inner join haunkohdejoukko as hajo on haku.kohdejoukkokoodiuri = hajo.versioitu_koodiuri
    left join haunkohdejoukontarkenne as hatr on haku.kohdejoukontarkennekoodiuri = hatr.versioitu_koodiuri
),

final as (
    select * from step1
)

select * from final
