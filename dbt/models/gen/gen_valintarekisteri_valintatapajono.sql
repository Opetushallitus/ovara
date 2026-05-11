{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with source as (
    select
        valintatapajono_oid as valintatapajono_id,
        {{ dbt_utils.star(from=ref('int_valintarekisteri_valintatapajono'), except=['valintatapajono_oid']) }}
    from {{ ref('int_valintarekisteri_valintatapajono') }}
),

final as (
    select
        valintatapajono_id,
        valintatapajono_nimi,
        hakukohde_oid,
        alinhyvaksyttypistemaara as alin_hyvaksytty_pistemaara,
        alkuperaisetaloituspaikat as alkuperaiset_aloituspaikat,
        aloituspaikat,
        eivarasijatayttoa as ei_varasijatayttoa,
        hakeneet,
        kaikkiehdontayttavathyvaksytaan as kaikki_ehdon_tayttavat_hyvaksytaan,
        poissaolevataytto as poissaoleva_taytto,
        prioriteetti,
        sijoiteltuilmanvarasijasaantojaniidenollessavoimassa as sijoiteltu_ilman_varasijasaanto_ja_niidenollessa_voimassa,
        tasasijasaanto,
        valintaesityshyvaksytty as valintaesitys_hyvaksytty,
        varasijantayttopaivat as varasijan_tayttopaivat,
        varasijat,
        varasijojakaytetaanasti as varasijoja_kaytetaan_asti
    from source
)

select * from final
