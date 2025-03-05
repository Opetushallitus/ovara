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

final as(
    select
        oid as valintatapajono_oid,
        nimi as valintatapajono_nimi,
        hakukohde_oid,
        alinhyvaksyttypistemaara,
        alkuperaisetaloituspaikat,
        aloituspaikat,
        eivarasijatayttoa,
        hakeneet,
        kaikkiehdontayttavathyvaksytaan,
        poissaolevataytto,
        prioriteetti,
        sijoiteltuilmanvarasijasaantojaniidenollessavoimassa,
        tasasijasaanto,
        valintaesityshyvaksytty,
        varasijantayttopaivat,
        varasijat,
        varasijojakaytetaanasti
    from raw
)

select * from final