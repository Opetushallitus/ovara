{{
  config(
    materialized = 'table',
    unlogged = true,
    indexes = [
        {'columns' : ['valintatapajono_oid']}
    ]
    )
}}

with valinnanvaiheet as (
    select
        hakukohde_oid,
        valinnanvaiheet
    from {{ ref('int_valintaperusteet_hakukohde') }}
),

final as (
    select
        vajo.oid as valintatapajono_oid,
        vajo.nimi as valintatapajono_nimi,
        vajo.tyyppi as valintatapajono_tyyppi,
        vv->>'valinnanVaiheOid' as valinnanvaihe_id,
        vava.hakukohde_oid,
        vajo."lastModified" as muokattu,
        vajo.prioriteetti,
        vajo.aloituspaikat,
        vajo.tasasijasaanto,
        vajo.valisijoittelu,
        vajo."merkitseMyohAuto" as merkitse_myoh_auto,
        vajo."eiVarasijatayttoa" as ei_varasijatayttoa,
        vajo."poissaOlevaTaytto" as poissaoleva_taytto,
        vajo.jarjestyskriteerit,
        vajo."poistetaankoHylatyt" as poistetaanko_hylatyt,
        vajo."valmisSijoiteltavaksi" as valmis_sijoiteltavaksi,
        vajo."siirretaanSijoitteluun" as siirretaan_sijoitteluun,
        vajo."kaytetaanValintalaskentaa" as kaytetaan_valintalaskentaa,
        vajo."kaikkiEhdonTayttavatHyvaksytaan" as kaikki_ehdon_tayttyvat_hyvaksytaan
    from valinnanvaiheet as vava
    cross join lateral jsonb_array_elements(vava.valinnanvaiheet) as vv
    cross join lateral jsonb_array_elements(vv -> 'valintatapajono') as elem
    cross join lateral jsonb_to_record(elem) as vajo (
        oid text,
        nimi text,
        tyyppi text,
        "lastModified" timestamp,
        prioriteetti integer,
        aloituspaikat integer,
        tasasijasaanto text,
        valisijoittelu boolean,
        "merkitseMyohAuto" boolean,
        "eiVarasijatayttoa" boolean,
        "poissaOlevaTaytto" boolean,
        jarjestyskriteerit jsonb,
        "poistetaankoHylatyt" boolean,
        "valmisSijoiteltavaksi" boolean,
        "siirretaanSijoitteluun" boolean,
        "kaytetaanValintalaskentaa" boolean,
        "kaikkiEhdonTayttavatHyvaksytaan" boolean
    )
)

select * from final
