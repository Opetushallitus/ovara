{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['haku_oid']},
            {'columns':['toteutus_oid']}
        ]
    )
}}

with hakukohde as (
    select * from {{ ref('int_kouta_hakukohde') }}
),

toteutus as (
    select * from {{ ref('pub_dim_toteutus') }}
),

haku as (
    select
        *,
        hakutapa_koodi = '05' as siirtohaku
    from {{ ref('pub_dim_haku') }}
),

koulutus as (
    select * from {{ ref('pub_dim_koulutus') }}
),

int as (
    select
        hako.hakukohde_oid,
        hako.hakukohde_nimi,
        hako.externalid as ulkoinen_tunniste,
        hako.tila,
        hako.haku_oid,
        hako.toteutus_oid,
        koul.koulutus_oid,
        hako.jarjestyspaikka_oid,
        hako.aloituspaikat,
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
            hako.koulutuksenalkamiskausi, (coalesce(haku.koulutuksen_alkamiskausi, tote.koulutuksen_alkamiskausi))
        ) as koulutuksen_alkamiskausi,
        hako.toinenasteonkokaksoistutkinto as toinen_aste_onko_kaksoistutkinto,
        coalesce(hako.jarjestaaurheilijanammkoulutusta, false) as jarjestaa_urheilijan_ammkoulutusta,
        tote.oppilaitoksen_opetuskieli
    from hakukohde as hako
    left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
    left join haku as haku on hako.haku_oid = haku.haku_oid
    left join koulutus as koul on tote.koulutus_oid = koul.koulutus_oid
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
        ulkoinen_tunniste,
        tila,
        haku_oid,
        toteutus_oid,
        koulutus_oid,
        jarjestyspaikka_oid,
        oppilaitoksen_opetuskieli,
        aloituspaikat,
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
                and date_part('month', koulutuksen_alkamispaivamaara) <= 6 then 'kausi_k#1'
            when
                koulutuksen_alkamiskausi_tyyppi = 'tarkka alkamisajankohta'
                and date_part('month', koulutuksen_alkamispaivamaara) >= 6 then 'kausi_s#1'
        end as koulutuksen_alkamiskausi_koodiuri,
        case
            when koulutuksen_alkamiskausi_tyyppi = 'alkamiskausi ja -vuosi' then koulutuksen_alkamisvuosi
            when
                koulutuksen_alkamiskausi_tyyppi = 'tarkka alkamisajankohta'
                then date_part('year', koulutuksen_alkamispaivamaara)
        end as koulutuksen_alkamisvuosi,
        henkilokohtaisen_suunnitelman_lisatiedot,
        toinen_aste_onko_kaksoistutkinto,
        jarjestaa_urheilijan_ammkoulutusta
    from step2
)

select * from final
order by haku_oid
