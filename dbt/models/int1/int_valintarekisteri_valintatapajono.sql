{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['valintatapajono_oid']}
    ]
    )
}}

with raw as (
    select distinct on (valintatapajono_oid) *
    from {{ ref('int_valintarekisteri_valintatapajono') }}
    order by valintatapajono_oid, dw_metadata_dw_stored_at desc
),

vp as (
    select distinct on (jono_id) jono_id, tyyppi_uri
    from {{ ref('int_valintaperusteet_valintatapajono') }}
    order by jono_id, muokattu desc
),

final as (
    select
        raw.valintatapajono_oid,
        raw.valintatapajono_nimi,
        raw.hakukohde_oid,
        raw.alinhyvaksyttypistemaara,
        raw.alkuperaisetaloituspaikat,
        raw.aloituspaikat,
        raw.eivarasijatayttoa,
        raw.hakeneet,
        raw.kaikkiehdontayttavathyvaksytaan,
        raw.poissaolevataytto,
        raw.prioriteetti,
        raw.sijoiteltuilmanvarasijasaantojaniidenollessavoimassa,
        raw.tasasijasaanto,
        raw.valintaesityshyvaksytty,
        raw.varasijantayttopaivat,
        raw.varasijat,
        raw.varasijojakaytetaanasti,
        vp.tyyppi_uri
    from raw
    left join vp on raw.valintatapajono_oid = vp.jono_id
)

select * from final
