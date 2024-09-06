--{{ ref('pub_dim_haku') }}
--{{ ref('pub_dim_toteutus') }}
    {{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['haku_oid']},
            {'columns':['toteutus_oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('int_kouta_hakukohde') }}
),

toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),


hakuajat as (
    select
        haku_oid,
        hakuajat
    from {{ ref('int_kouta_haku') }}
),

int as (
    select
        raw1.hakukohde_oid,
        raw1.hakukohde_nimi,
        raw1.externalid,
        raw1.tila,
        raw1.haku_oid,
        raw1.toteutus_oid,
        raw1.jarjestyspaikka_oid,
        raw1.aloituspaikat,
        raw1.aloituspaikat_ensikertalaisille,
        raw1.hakukohdekoodiuri,
        raw1.pohjakoulutuskoodit,
        case
            when raw1.kaytetaanhaunaikataulua
                then hajt.hakuajat
            else raw1.hakuajat
        end as hakuajat,
        raw1.kaytetaanhaunaikataulua as kaytetaan_haun_aikataulua
    from raw as raw1
    left join toteutus as tote on raw1.toteutus_oid = tote.toteutus_oid
    left join hakuajat as hajt on raw1.haku_oid = hajt.haku_oid

)

select * from int
