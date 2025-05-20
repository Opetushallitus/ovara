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

toteutus as (
    select distinct
        haku_oid,
        koulutuksen_alkamiskausikoodi
    from {{ ref('int_toteutus_koulutuksen_alkamiskausi') }}
    where haku_oid is not null
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

toteutus_koulutuksen_alkamiskausi as (
    select
        haku_oid,
        jsonb_agg(koulutuksen_alkamiskausikoodi) as koulutuksen_alkamiskausikoodi
    from toteutus
    group by 1
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
        coalesce(haku.koulutuksen_alkamiskausikoodi, tote.koulutuksen_alkamiskausikoodi) as koulutuksen_alkamiskausi,
        haku.haun_tyyppi
    from haku as haku
    inner join hakutapakoodi as hata on haku.hakutapakoodiuri = hata.versioitu_koodiuri
    inner join haunkohdejoukko as hajo on haku.kohdejoukkokoodiuri = hajo.versioitu_koodiuri
    left join haunkohdejoukontarkenne as hatr on haku.kohdejoukontarkennekoodiuri = hatr.versioitu_koodiuri
    left join toteutus_koulutuksen_alkamiskausi as tote on haku.haku_oid = tote.haku_oid
),

final as (
    select * from step1
)

select * from final
