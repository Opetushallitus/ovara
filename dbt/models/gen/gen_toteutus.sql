{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['toteutus_oid']}
    ]
    )
}}

with toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

final as (
    select
        toteutus_oid,
        toteutus_nimi ->> 'fi' as toteutus_nimi_fi,
        toteutus_nimi ->> 'sv' as toteutus_nimi_sv,
        toteutus_nimi ->> 'en' as toteutus_nimi_en,
        koulutus_oid,
        organisaatio_oid,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz as koulutuksen_tarkka_alkamisaika,
        (koulutuksen_alkamiskausi ->> 'koulutuksenPaattymispaivamaara')::timestamptz
        as koulutuksen_tarkka_paattymispaiva,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksen_alkamisvuosi,
        koulutuksen_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksen_alkamiskausiuri,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'fi'
        as henkilokohtaisen_suunnitelman_lisatiedot_fi,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'sv'
        as henkilokohtaisen_suunnitelman_lisatiedot_sv,
        koulutuksen_alkamiskausi -> 'henkilokohtaisenSuunnitelmanLisatiedot' ->> 'en'
        as henkilokohtaisen_suunnitelman_lisatiedot_en,
        externalid as ulkoinen_tunniste,
        tila,
        esikatselu,
        tarjoajat,
        tyyppi,
        kuvaus_fi as toteutus_kuvaus_fi,
        kuvaus_sv as toteutus_kuvaus_sv,
        kuvaus_en as toteutus_kuvaus_en,
        osaamisalat,
        opetuskielikoodiurit as opetuskieli_koodiurit,
        opetuskieletkuvaus_fi as opetuskielet_kuvaus_fi,
        opetuskieletkuvaus_sv as opetuskielet_kuvaus_sv,
        opetuskieletkuvaus_en as opetuskielet_kuvaus_en,
        opetusaikakoodiurit as opetusaika_koodiurit,
        opetusaikakuvaus ->> 'fi' as opetusaika_kuvaus_fi,
        opetusaikakuvaus ->> 'sv' as opetusaika_kuvaus_sv,
        opetusaikakuvaus ->> 'en' as opetusaika_kuvaus_en,
        opetustapakoodiurit as opetustapa_koodiurit,
        opetustapakuvaus as opetustapa_kuvaus,
        maksullisuustyyppi as maksullisuus_tyyppi,
        maksullisuuskuvaus ->> 'fi' as maksullisuus_kuvaus_fi,
        maksullisuuskuvaus ->> 'sv' as maksullisuus_kuvaus_sv,
        maksullisuuskuvaus ->> 'en' as maksullisuus_kuvaus_en,
        maksunmaara as maksun_maara,
        lisatiedot -> 'fi' as toteutus_lisatiedot_fi,
        lisatiedot -> 'sv' as toteutus_lisatiedot_sv,
        lisatiedot -> 'en' as toteutus_lisatiedot_en,
        onkoapuraha as onko_apuraha,
        suunniteltukestovuodet as suunniteltu_kesto_vuodet,
        suunniteltukestokuukaudet as suunniteltu_kesto_kuukaudet,
        suunniteltukestokuvaus ->> 'fi' as suunniteltu_kesto_kuvaus_fi,
        suunniteltukestokuvaus ->> 'sv' as suunniteltu_kesto_kuvaus_sv,
        suunniteltukestokuvaus ->> 'en' as suunniteltu_kesto_kuvaus_en,
        asiasanat,
        ammattinimikkeet,
        ishakukohteetkaytossa as onko_hakukohteet_kaytossa,
        hakutermi,
        hakulomaketyyppi as hakulomake_tyyppi,
        hakulomakelinkki as hakulomake_linkki,
        lisatietoahakeutumisesta ->> 'fi' as lisatietoa_hakeutumisesta_fi,
        lisatietoahakeutumisesta ->> 'sv' as lisatietoa_hakeutumisesta_sv,
        lisatietoahakeutumisesta ->> 'en' as lisatietoa_hakeutumisesta_en,
        lisatietoavalintaperusteista ->> 'fi' as lisatietoa_valintaperusteista_fi,
        lisatietoavalintaperusteista ->> 'sv' as lisatietoa_valintaperusteista_sv,
        lisatietoavalintaperusteista ->> 'en' as lisatietoa_valintaperusteista_en,
        hakuaika,
        aloituspaikat,
        aloituspaikkakuvaus ->> 'fi' as aloituspaikka_kuvaus_fi,
        aloituspaikkakuvaus ->> 'sv' as aloituspaikka_kuvaus_sv,
        aloituspaikkakuvaus ->> 'en' as aloituspaikka_kuvaus_en,
        isavoinkorkeakoulutus as onko_avoin_korkeakoulutus,
        tunniste,
        opinnontyyppikoodiuri as opinnon_tyyppi_koodiuri,
        liitetytopintojaksot as liitetyt_opintojaksot,
        ammatillinenperustutkintoerityisopetuksena as ammatillinen_perustutkinto_erityisopetuksena,
        opintojenlaajuusyksikkokoodiuri as opintojen_laajuus_yksikko_koodiuri,
        opintojenlaajuusnumero as opintojen_laajuus_numero,
        hasjotparahoitus as on_jotpa_rahoitus,
        istaydennyskoulutus as onko_taydennyskoulutus,
        istyovoimakoulutus as onko_tyovoimakoulutus,
        kielivalikoima,
        yleislinja,
        painotukset,
        erityisetkoulutustehtavat as erityiset_koulutustehtavat,
        diplomit,
        jarjestetaanerityisopetuksena as jarjestetaan_erityisopetuksena,
        taiteenalakoodiurit as taiteenala_koodiurit,
        sorakuvausid as sorakuvaus_id,
        kielivalinta,
        teemakuva,
        ispieniosaamiskokonaisuus as onko_pieni_osaamiskokonaisuus
    from toteutus
)

select * from final
