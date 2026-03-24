{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['haku_oid']}
    ]
    )
}}
with haku as (
    select * from {{ ref('int_kouta_haku') }}
),

kausi as (
    select
        versioitu_koodiuri,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_kausi') }}
),

hakutapa as (
    select
        versioitu_koodiuri,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_hakutapa') }}
),

taulu as (
    select
        haku_oid,
        haku_nimi ->> 'fi' as haku_nimi_fi,
        haku_nimi ->> 'sv' as haku_nimi_sv,
        haku_nimi ->> 'en' as haku_nimi_en,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz as koulutuksen_tarkka_alkamisaika,
        (koulutuksen_alkamiskausi ->> 'koulutuksenPaattymispaivamaara')::timestamptz as koulutuksen_tarkka_paattymispaiva,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksen_alkamisvuosi,
        koulutuksen_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksen_alkamiskausiuri,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'fi' as henkilokohtaisen_suunnitelman_lisatiedot_fi,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'sv' as henkilokohtaisen_suunnitelman_lisatiedot_sv,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'en' as henkilokohtaisen_suunnitelman_lisatiedot_en,
        externalid,
        tila,
        hakutapakoodiuri,
        hakukohteenliittamisentakaraja as hakukohteen_liittamisen_takaraja,
        hakukohteenmuokkaamisentakaraja as hakukohteen_muokkaamisen_takaraja,
        hakukohteenliittajaorganisaatiot as hakukohteen_liittaja_organisaatiot,
        ajastettujulkaisu as ajastettu_julkaisu,
        ajastettuhaunjahakukohteidenarkistointi,
        ajastettuhaunjahakukohteidenarkistointiajettu,
        kohdejoukkokoodiuri,
        kohdejoukontarkennekoodiuri,
        hakulomaketyyppi,
        hakulomakeataruid,
        hakulomakekuvaus,
        hakulomakelinkki,
        tulevaisuudenaikataulu,
        organisaatiooid
    from haku
),

nimi as (
    select
    taul.*,
    kaus.nimi_fi as kausi_nimi_fi,
    kaus.nimi_sv as kausi_nimi_sv,
    kaus.nimi_en as kausi_nimi_en,
    hata.nimi_fi as hakutapa_nimi_fi,
    hata.nimi_sv as hakutapa_nimi_sv,
    hata.nimi_en as hakutapa_nimi_en
    from taulu as taul
    left join kausi as kaus on taul.koulutuksen_alkamiskausiuri = kaus.versioitu_koodiuri
    left join hakutapa as hata on taul.hakutapakoodiuri = hata.versioitu_koodiuri
)

select * from nimi