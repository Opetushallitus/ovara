{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['jono_id']},
        {'columns': ['hakukohde_oid']}
    ]
  )
}}

with hakukohde as (
    select * from {{ ref('dw_valintaperusteet_hakukohde') }}
),

valintatapajonoja as (
    select
        hakukohde_oid,
        muokattu,
        vaihe ->> 'id' as valinnanvaihe_id,
        jsonb_array_elements(vaihe -> 'valintatapajono') as data
    from hakukohde,
        lateral jsonb_array_elements(valinnanvaiheet) as vaihe
),

rivit as (
    select
        data ->> 'oid' as jono_id,
        valinnanvaihe_id,
        hakukohde_oid,
        muokattu,
        data ->> 'nimi' as nimi,
        data ->> 'kuvaus' as kuvaus,
        (data ->> 'aloituspaikat')::int as aloituspaikat,
        data ->> 'tyyppi' as tyyppi_uri,
        (data ->> 'prioriteetti')::int as prioriteetti,
        (data ->> 'siirretaanSijoitteluun')::boolean as siirretaan_sijoitteluun,
        data ->> 'tasasijasaanto' as tasasijasaanto,
        (data ->> 'eiLasketaPaivamaaranJalkeen')::timestamptz as ei_lasketa_paivamaaran_jalkeen,
        (data ->> 'eiVarasijatayttoa')::boolean as ei_varasijatayttoa,
        (data ->> 'merkitseMyohAuto')::boolean as merkitse_myoh_auto,
        (data ->> 'poissaOlevaTaytto')::boolean as poissa_oleva_taytto,
        (data ->> 'kaikkiEhdonTayttavatHyvaksytaan')::boolean as kaikki_ehdon_tayttavat_hyvaksytaan,
        (data ->> 'kaytetaanValintalaskentaa')::boolean as kaytetaan_valintalaskentaa,
        (data ->> 'valmisSijoiteltavaksi')::boolean as valmis_sijoiteltavaksi,
        (data ->> 'valisijoittelu')::boolean as valisijoittelu,
        (data ->> 'poistetaankoHylatyt')::boolean as poistetaanko_hylatyt,
        data -> 'jarjestyskriteerit' as jarjestyskriteerit
    from valintatapajonoja
    where data ->> 'oid' is not null
)

select * from rivit
