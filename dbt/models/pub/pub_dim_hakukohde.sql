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
        end as tutkinnon_taso_sykli
    from hakukohde as hako
    left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
    left join haku as haku on hako.haku_oid = haku.haku_oid
    left join koulutus as koul on tote.koulutus_oid = koul.koulutus_oid
)

select * from int
