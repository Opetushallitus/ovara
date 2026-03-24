{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_oid']}
    ]
    )
}}

with hakukohde as (
    select * from {{ ref('int_kouta_hakukohde') }}
),

final as (
    select
        hakukohde_oid,
        toteutus_oid,
        haku_oid,
        jarjestyspaikka_oid,
        ulkoinen_tunniste,
        hakukohde_nimi ->> 'fi' as hakukohde_nimi_fi,
        hakukohde_nimi ->> 'sv' as hakukohde_nimi_sv,
        hakukohde_nimi ->> 'en' as hakukohde_nimi_en,
        organisaatio_oid,
        valintaperuste_id,
        tila,
        esikatselu,
        hakukohdekoodiuri as hakukohde_koodiuri,
        hakulomaketyyppi as hakulomake_tyyppi,
        hakulomakeataruid as hakulomake_ataru_id,
        hakulomakekuvaus ->> 'fi' as hakulomake_kuvaus_fi,
        hakulomakekuvaus ->> 'sv' as hakulomake_kuvaus_sv,
        hakulomakekuvaus ->> 'en' as hakulomake_kuvaus_en,
        hakulomakelinkki ->> 'fi' as hakulomake_linkki_fi,
        hakulomakelinkki ->> 'sv' as hakulomake_linkki_sv,
        hakulomakelinkki ->> 'en' as hakulomake_linkki_en,
        kaytetaanhaunhakulomaketta as kaytetaan_haun_hakulomaketta,
        pohjakoulutusvaatimuskoodiurit as pohjakoulutusvaatimus_koodiurit,
        pohjakoulutusvaatimustarkenne ->> 'fi' as pohjakoulutusvaatimus_tarkenne_fi,
        pohjakoulutusvaatimustarkenne ->> 'sv' as pohjakoulutusvaatimus_tarkenne_sv,
        pohjakoulutusvaatimustarkenne ->> 'en' as pohjakoulutusvaatimus_tarkenne_en,
        muupohjakoulutusvaatimus as muu_pohjakoulutusvaatimus,
        toinenasteonkokaksoistutkinto as toinen_aste_onko_kaksoistutkinto,
        kaytetaanhaunaikataulua as kaytetaan_haun_aikataulua,
        liitteetonkosamatoimitusaika as liitteet_onko_sama_toimitusaika,
        liitteetonkosamatoimitusosoite as liitteet_onko_sama_toimitusosoite,
        liitteidentoimitusaika as liitteiden_toimitusaika,
        liitteidentoimitustapa as liitteiden_toimitustapa,
        liitteidentoimitusosoite as liitteiden_toimitusosoite,
        liitteet,
        valintakokeet,
        hakuajat,
        valintakokeidenyleiskuvaus ->> 'fi' as valintakokeiden_yleiskuvaus_fi,
        valintakokeidenyleiskuvaus ->> 'sv' as valintakokeiden_yleiskuvaus_sv,
        valintakokeidenyleiskuvaus ->> 'en' as valintakokeiden_yleiskuvaus_en,
        valintaperusteenvalintakokeidenlisatilaisuudet as valintaperusteen_valintakokeiden_lisatilaisuudet,
        kynnysehto ->> 'fi' as kynnysehto_fi,
        kynnysehto ->> 'sv' as kynnysehto_sv,
        kynnysehto ->> 'en' as kynnysehto_en,
        kaytetaanhaunalkamiskautta as kaytetaan_haun_alkamiskautta,
        (koulutuksenalkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz as koulutuksen_alkamispaivamaara,
        (koulutuksenalkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksen_alkamisvuosi,
        koulutuksenalkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksen_alkamiskausiuri,
        aloituspaikat,
        aloituspaikat_ensikertalaisille,
        aloituspaikat_kuvaus ->> 'fi' as aloituspaikat_kuvaus_fi,
        aloituspaikat_kuvaus ->> 'sv' as aloituspaikat_kuvaus_sv,
        aloituspaikat_kuvaus ->> 'en' as aloituspaikat_kuvaus_en,
        hakukohteenlinja as hakukohteen_linja,
        painotetutarvosanat as painotetut_arvosanat,
        uudenopiskelijanurl ->> 'fi' as uuden_opiskelijan_url_fi,
        uudenopiskelijanurl ->> 'sv' as uuden_opiskelijan_url_sv,
        uudenopiskelijanurl ->> 'en' as uuden_opiskelijan_url_en,
        jarjestaaurheilijanammkoulutusta as jarjestaa_urheilijan_ammkoulutusta,
        kielivalinta
    from hakukohde
)

select * from final
