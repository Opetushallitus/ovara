{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['valintatapajono_oid']}
    ]
    )
}}

with raw as (
    select * from {{ ref('dw_valintarekisteri_valintatapajono') }}
)

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
    raw.dw_metadata_dw_stored_at
from raw
