{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['oid']},
            {'columns':['haku_oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('int_kouta_hakukohde') }}
),

toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

koulutus as (
    select * from {{ ref('int_kouta_koulutus') }}
),

hakuajat as (
    select
        oid,
        hakuajat
    from {{ ref('int_kouta_haku') }}
),

alempi_ylempi_raw as (
select
 	koko.oid,
 	--b.koodiarvo,
 	case when left(kood.koodiarvo,1)='6' then 1 else 0 end as alempi,
 	case when left(kood.koodiarvo,1)='7' then 1 else 0 end as ylempi
 	from {{ ref('int_koulutus_koulutuskoodi') }} koko
    left join {{ ref('int_koodisto_koulutus') }} kood on koko.koulutuskoodiuri=kood.versioitu_koodiuri

),

alempi_ylempi as (
    select
        oid as koulutus_oid,
        case when sum(alempi) > 0 then 1 else 0 end as alempikk,
        case when sum(ylempi) > 0 then 1 else 0 end as ylempikk
    from alempi_ylempi_raw
     group by 1
),

int as (
    select
        raw1.oid,
        raw1.nimi_fi,
        raw1.nimi_sv,
        raw1.nimi_en,
        raw1.externalid,
        raw1.tila,
        raw1.haku_oid,
        raw1.toteutus_oid,
        raw1.aloituspaikat,
        alyl.alempikk,
        alyl.ylempikk,
        case
            when raw1.kaytetaanHaunAikataulua
            then hajt.hakuajat
            else raw1.hakuajat
            end as hakuajat,
        raw1.kaytetaanHaunAikataulua as kaytetaan_haun_aikataulua
    from raw as raw1
    left join toteutus as tote on raw1.toteutus_oid = tote.oid
    left join koulutus as koul on tote.koulutus_oid = koul.oid
    left join alempi_ylempi as alyl on koul.oid = alyl.koulutus_oid
    left join hakuajat as hajt on raw1.haku_oid = hajt.oid

)

select * from int
