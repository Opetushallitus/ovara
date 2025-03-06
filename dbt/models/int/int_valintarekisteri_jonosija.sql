{{
  config(
    indexes = [
        {'columns': ['hakemus_hakukohde_valintatapa_id']}
    ]
    )
}}

with raw as (
    select distinct on (id) * from {{ ref('dw_valintarekisteri_jonosija') }}
    order by id asc, muokattu desc
),

final as (
    select
        {{ hakutoive_id() }},
        {{ dbt_utils.generate_surrogate_key(['hakemus_oid','hakukohde_oid','valintatapajono_oid']) }}
        as hakemus_hakukohde_valintatapa_id,
        id,
        hakemus_oid,
        hakukohde_oid,
        valintatapajono_oid,
        hyvaksytty_harkinnanvaraisesti,
        jonosija,
        varasijan_numero,
        onko_muuttunut_viime_sijoittelussa,
        prioriteetti,
        pisteet,
        siirtynyt_toisesta_valintatapajonosta,
        sijoitteluajo_id
    from raw
)

select * from final
