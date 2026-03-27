{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['valintatapajono_oid']}
    ]
    )
}}

with raw as (
    select * from {{ ref('dw_valintarekisteri_valintatapajono') }}
),

vp as (
    select jono_id, tyyppi_uri
    from {{ ref('int_valintaperusteet_valintatapajono') }}
),

final as (
    select
        raw.oid as valintatapajono_oid,
        raw.nimi as valintatapajono_nimi,
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
    left join vp on raw.oid = vp.jono_id
)

select * from final
