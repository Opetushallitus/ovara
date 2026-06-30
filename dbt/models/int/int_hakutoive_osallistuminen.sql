{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakutoive_id']}
    ],
    enabled=false
    )
}}

with source as (
	select * from {{ ref('int_valintalaskenta_valintakoe_osallistuminen') }}
),

rows as (
    select
        hakemusoid as hakemus_oid,
        elem."hakukohdeOid" as hakukohde_oid,
        vako.nimi,
        vako.aktiivinen,
        vako."lastModified" as last_modified,
        vako."valintakoeOid" as valintakoe_oid,
        vako."valintakoeTunniste" as valintakoe_tunniste,
        vako."osallistuminenTulos" ->> 'laskentaTila' as laskenta_tila,
        vako."osallistuminenTulos" ->> 'laskentaTulos' as laskenta_tulos,
        vako."osallistuminenTulos" ->> 'osallistuminen' as osallistuminen,
        vako."lahetetaankoKoekutsut" as lahetetaanko_koekutsut
    from source
    cross join lateral jsonb_to_recordset(hakutoiveet) as elem(
        "hakukohdeOid" text,
        "valinnanVaiheet" jsonb)

        cross join lateral jsonb_to_recordset (elem."valinnanVaiheet") as vava(
        valintakokeet jsonb)


    cross join lateral jsonb_to_recordset(vava.valintakokeet) as vako(
        nimi text,
        aktiivinen boolean,
        "lastModified" timestamptz,
        "valintakoeOid" text,
        "valintakoeTunniste" text,
        "osallistuminenTulos" jsonb,
        "lahetetaankoKoekutsut" boolean
        )
),

final as (
    select
        {{ hakutoive_id() }},
        *
    from rows
)

select * from final
