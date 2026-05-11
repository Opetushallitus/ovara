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

hak2 as (
    select
        haku_oid,
        haku_vuosi,
        haku_kausi
    from {{ ref('int_haku') }}
),

final as (
    select
        haku.haku_oid,
        haku.haku_nimi ->> 'fi' as haku_nimi_fi,
        haku.haku_nimi ->> 'sv' as haku_nimi_sv,
        haku.haku_nimi ->> 'en' as haku_nimi_en,
        haku.externalid as ulkoinen_tunniste,
        (haku.koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz
        as koulutuksen_tarkka_alkamisaika,
        (haku.koulutuksen_alkamiskausi ->> 'koulutuksenPaattymispaivamaara')::timestamptz
        as koulutuksen_tarkka_paattymispaiva,
        (haku.koulutuksen_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksen_alkamisvuosi,
        haku.koulutuksen_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksen_alkamiskausiuri,
        haku.koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'fi'
        as henkilokohtaisen_suunnitelman_lisatiedot_fi,
        haku.koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'sv'
        as henkilokohtaisen_suunnitelman_lisatiedot_sv,
        haku.koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'en'
        as henkilokohtaisen_suunnitelman_lisatiedot_en,
        haku.tila,
        haku.hakutapakoodiuri,
        haku.hakukohteenliittamisentakaraja as hakukohteen_liittamisen_takaraja,
        haku.hakukohteenmuokkaamisentakaraja as hakukohteen_muokkaamisen_takaraja,
        haku.hakukohteenliittajaorganisaatiot as hakukohteen_liittaja_organisaatiot,
        haku.ajastettujulkaisu as ajastettu_julkaisu,
        haku.ajastettuhaunjahakukohteidenarkistointi as ajastettu_haun_ja_hakukohteiden_arkistointi,
        haku.ajastettuhaunjahakukohteidenarkistointiajettu as ajastettu_haun_ja_hakukohteiden_arkistointi_ajettu,
        haku.kohdejoukkokoodiuri as kohdejoukko_koodiuri,
        haku.kohdejoukontarkennekoodiuri as kohdejoukon_tarkenne_koodiuri,
        haku.hakulomaketyyppi as hakulomake_tyyppi,
        haku.hakulomakeataruid as hakulomake_ataru_id,
        haku.hakulomakekuvaus ->> 'fi' as hakulomake_kuvaus_fi,
        haku.hakulomakekuvaus ->> 'sv' as hakulomake_kuvaus_sv,
        haku.hakulomakekuvaus ->> 'en' as hakulomake_kuvaus_en,
        haku.hakulomakelinkki ->> 'fi' as hakulomake_linkki_fi,
        haku.hakulomakelinkki ->> 'sv' as hakulomake_linkki_sv,
        haku.hakulomakelinkki ->> 'en' as hakulomake_linkki_en,
        haku.tulevaisuudenaikataulu,
        haku.organisaatiooid as organisaatio_oid,
        hak2.haku_vuosi,
        hak2.haku_kausi
    from haku
    left join hak2 on haku.haku_oid = hak2.haku_oid
)

select * from final
