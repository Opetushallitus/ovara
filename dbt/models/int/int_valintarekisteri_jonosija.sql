{{
  config(
    indexes = [
        {'columns': ['hakemus_hakukohde_valintatapa_id']}
    ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by id order by muokattu desc) as rownr
    from {{ ref('dw_valintarekisteri_jonosija') }}
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
    where rownr = 1
)

select * from final
