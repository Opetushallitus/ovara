{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakutoive_id']}
    ]
    )
}}

with valinnantulos as (
    select * from {{ ref('int_valintarekisteri_valinnantulos') }}
),

jonosija as (
    select * from {{ ref('int_valintarekisteri_jonosija') }}
),

jono as (
    select * from {{ ref('int_valintarekisteri_valintatapajono') }}
),

rivit as (
    select
        vatu.hakutoive_id,
        jsonb_build_object(
            'valintatapajono_oid', vatu.valintatapajono_oid,
            'valintatapajono_nimi', jono.valintatapajono_nimi,
            'valinnan_tila', case
                when
                    vatu.valinnan_tila in ('HYVAKSYTTY', 'HYVAKSYTTY_VARASIJALTA')
                    and josi.hyvaksytty_harkinnanvaraisesti
                    then 'HARKINNANVARAISESTI_HYVÄKSYTTY'
                else vatu.valinnan_tila
            end,
            'ehdollisesti_hyvaksyttavissa', vatu.ehdollisesti_hyvaksyttavissa,
            'ehdollisen_hyvaksymisen_ehto', vatu.ehdollisen_hyvaksymisen_ehto,
            'valinnantilan_kuvauksen_teksti', vatu.valinnantilan_kuvauksen_teksti,
            'julkaistavissa', vatu.julkaistavissa,
            'hyvaksyperuuntunut', vatu.hyvaksyperuuntunut,
            'hyvaksytty_harkinnanvaraisesti', josi.hyvaksytty_harkinnanvaraisesti,
            'jonosija', josi.jonosija,
            'varasijan_numero', josi.varasijan_numero,
            'onko_muuttunut_viime_sijoittelussa', josi.onko_muuttunut_viime_sijoittelussa,
            'prioriteetti', josi.prioriteetti,
            'pisteet', josi.pisteet,
            'siirtynyt_toisesta_valintatapajonosta', josi.siirtynyt_toisesta_valintatapajonosta
        ) as valintatapajonot,
        valintatiedon_pvm
    from valinnantulos as vatu
    left join jonosija as josi on vatu.hakemus_hakukohde_valintatapa_id = josi.hakemus_hakukohde_valintatapa_id
    left join jono on vatu.valintatapajono_oid = jono.valintatapajono_oid
),

valintatapajonot as (
    select
        hakutoive_id,
        jsonb_agg(valintatapajonot) as valintatapajonot,
        valintatiedon_pvm
    from rivit
    group by
        hakutoive_id,
        valintatiedon_pvm
),

final as (
    select
        hakutoive_id,
        valintatapajonot,
        case
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "HYVAKSYTTY")'
                then 'HYVAKSYTTY'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "HARKINNANVARAISESTI_HYVAKSYTTY")'
                then 'HARKINNANVARAISESTI_HYVAKSYTTY'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "VARASIJALTA_HYVAKSYTTY")'
                then 'VARASIJALTA_HYVAKSYTTY'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "VARALLA")'
                then 'VARALLA'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "PERUUTETTU")'
                then 'PERUUTETTU'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "PERUNUT")'
                then 'PERUNUT'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "PERUUNTUNUT")'
                then 'PERUNUT'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "HYLATTY")'
                then 'HYLATTY'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "KESKEN")'
                then 'KESKEN'
            else null
        end as valintatieto,
        valintatiedon_pvm
    from valintatapajonot
)

select * from final
