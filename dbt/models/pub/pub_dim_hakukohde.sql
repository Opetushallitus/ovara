{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['haku_oid']},
            {'columns':['toteutus_oid']},
            {'columns':['koulutus_oid']}
        ]
    )
}}

with hakukohde as (
    select * from {{ ref('int_hakukohde') }}
),

toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

haku as (
    select * from {{ ref('int_haku') }}
),

koulutus as (
    select * from {{ ref('pub_dim_koulutus') }}
),

organisaatio as (
    select * from {{ ref('pub_dim_organisaatio') }}
),

organisaatio_hakukohteiden_nimet as (
    select * from {{ ref('int_organisaatio_hakukohteiden_nimet') }}
),

int as (
    select
        hako.hakukohde_oid,
        hako.hakukohde_nimi,
        hani.organisaatio_nimi,
        hani.toimipiste,
        hani.toimipiste_nimi,
        hani.oppilaitos,
        hani.oppilaitos_nimi,
        hani.koulutustoimija,
        hani.koulutustoimija_nimi,
        hako.ulkoinen_tunniste,
        hako.tila,
        hako.haku_oid,
        hako.toteutus_oid,
        koul.koulutus_oid,
        hako.jarjestyspaikka_oid,
        orga.organisaatio_nimi as jarjestyspaikka_nimi,
        orga.sijaintikunta,
        orga.sijaintikunta_nimi,
        orga.sijaintimaakunta,
        orga.sijaintimaakunta_nimi,
        hako.hakukohteen_aloituspaikat,
        hako.valintaperusteiden_aloituspaikat,
        hako.aloituspaikat_ensikertalaisille,
        hako.hakukohdekoodiuri,
        case
            when hako.kaytetaanhaunaikataulua
                then haku.hakuajat
            else hako.hakuajat
        end as hakuajat,
        hako.kaytetaanhaunaikataulua as kaytetaan_haun_aikataulua,
        hako.on_valintakoe,
        case
            when koul.jatkotutkinto then 5
            when haku.siirtohaku and koul.alempi_kk_aste then 2
            when haku.siirtohaku and not koul.alempi_kk_aste and koul.laakis then 2
            when haku.siirtohaku and not koul.alempi_kk_aste and koul.ylempi_kk_aste then 4
            when haku.siirtohaku then -1
            when koul.alempi_kk_aste then 1
            when koul.alempi_kk_aste and not koul.ylempi_kk_aste and koul.laakis then 1
            when not koul.alempi_kk_aste and koul.ylempi_kk_aste then 3
            else 6
        end as tutkinnon_taso_sykli,
        coalesce(
            hako.koulutuksen_alkamiskausi, haku.koulutuksen_alkamiskausi, tote.koulutuksenalkamiskausi
        ) as koulutuksen_alkamiskausi,
        hako.toinenasteonkokaksoistutkinto as toinen_aste_onko_kaksoistutkinto,
        coalesce(hako.jarjestaaurheilijanammkoulutusta, false) as jarjestaa_urheilijan_ammkoulutusta,
        hako.oppilaitoksen_opetuskieli,
        koul.alempi_kk_aste,
        koul.ylempi_kk_aste,
        koul.okm_ohjauksen_ala,
        hako.valintaperuste_nimi
    from hakukohde as hako
    left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
    left join haku as haku on hako.haku_oid = haku.haku_oid
    left join koulutus as koul on tote.koulutus_oid = koul.koulutus_oid
    left join organisaatio as orga on hako.jarjestyspaikka_oid = orga.organisaatio_oid
    left join organisaatio_hakukohteiden_nimet as hani on hako.jarjestyspaikka_oid = hani.jarjestyspaikka_oid
),

step2 as (
    select
        *,
        koulutuksen_alkamiskausi ->> 'alkamiskausityyppi' as koulutuksen_alkamiskausi_tyyppi,
        koulutuksen_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksen_alkamiskausi_koodiuri,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksen_alkamisvuosi,
        (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::date as koulutuksen_alkamispaivamaara,
        koulutuksen_alkamiskausi ->> 'henkilokohtaisenSuunnitelmanLisatiedot'
        as henkilokohtaisen_suunnitelman_lisatiedot
    from int
),

final as (
    select
        hakukohde_oid,
        hakukohde_nimi,
        organisaatio_nimi,
        toimipiste,
        toimipiste_nimi,
        oppilaitos,
        oppilaitos_nimi,
        koulutustoimija,
        koulutustoimija_nimi,
        ulkoinen_tunniste,
        tila,
        haku_oid,
        toteutus_oid,
        koulutus_oid,
        jarjestyspaikka_oid,
        jarjestyspaikka_nimi,
        sijaintikunta,
        sijaintikunta_nimi,
        sijaintimaakunta,
        sijaintimaakunta_nimi,
        oppilaitoksen_opetuskieli,
        hakukohteen_aloituspaikat,
        valintaperusteiden_aloituspaikat,
        aloituspaikat_ensikertalaisille,
        hakukohdekoodiuri,
        hakuajat,
        kaytetaan_haun_aikataulua,
        on_valintakoe,
        tutkinnon_taso_sykli,
        koulutuksen_alkamiskausi,
        koulutuksen_alkamiskausi_tyyppi,
        case
            when koulutuksen_alkamiskausi_tyyppi = 'alkamiskausi ja -vuosi' then koulutuksen_alkamiskausi_koodiuri
            when
                koulutuksen_alkamiskausi_tyyppi = 'tarkka alkamisajankohta'
                and date_part('month', koulutuksen_alkamispaivamaara) <= 7 then 'kausi_k#1'
            when
                koulutuksen_alkamiskausi_tyyppi = 'tarkka alkamisajankohta'
                and date_part('month', koulutuksen_alkamispaivamaara) > 7 then 'kausi_s#1'
        end as koulutuksen_alkamiskausi_koodiuri,
        case
            when koulutuksen_alkamiskausi_tyyppi = 'alkamiskausi ja -vuosi' then koulutuksen_alkamisvuosi
            when
                koulutuksen_alkamiskausi_tyyppi = 'tarkka alkamisajankohta'
                then date_part('year', koulutuksen_alkamispaivamaara)
        end as koulutuksen_alkamisvuosi,
        henkilokohtaisen_suunnitelman_lisatiedot,
        toinen_aste_onko_kaksoistutkinto,
        jarjestaa_urheilijan_ammkoulutusta,
        alempi_kk_aste,
        ylempi_kk_aste,
        okm_ohjauksen_ala,
        valintaperuste_nimi
    from step2
)

select * from final
order by haku_oid
