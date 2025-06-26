{{
  config(
    materialized = 'table',
    index = [
        {'columns': ['jonosija_id']},
        {'columns': ['hakutoive_id']},
        {'columns': ['hakemus_hakukohde_valintatapa_id']}
    ]
    )
}}

with raw as (
    select * from {{ ref('dw_valintarekisteri_jonosija') }}
),

final as (
    select
        jonosija_id,
        {{ dbt_utils.generate_surrogate_key(['hakemus_oid','hakukohde_oid','valintatapajono_oid']) }}
        as hakemus_hakukohde_valintatapa_id,
        {{ hakutoive_id() }},
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
