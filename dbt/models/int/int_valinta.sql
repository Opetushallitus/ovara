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
            'valintatiedon_pvm', vatu.valintatiedon_pvm,
            'ehdollisesti_hyvaksytty', case
                when
                    vatu.valinnan_tila in ('HYVAKSYTTY', 'HYVAKSYTTY_VARASIJALTA')
                    and vatu.ehdollisesti_hyvaksyttavissa
                    then true
                else false
            end,
            'ehdollisen_hyvaksymisen_ehto', vatu.ehdollisen_hyvaksymisen_ehto,
            'valinnantilan_kuvauksen_teksti', vatu.valinnantilan_kuvauksen_teksti,
            'julkaistavissa', vatu.julkaistavissa,
            'hyvaksyperuuntunut', vatu.hyvaksyperuuntunut,
            'hyvaksytty_harkinnanvaraisesti', josi.hyvaksytty_harkinnanvaraisesti,
            'jonosija', josi.jonosija,
            'onko_muuttunut_viime_sijoittelussa', josi.onko_muuttunut_viime_sijoittelussa,
            'prioriteetti', josi.prioriteetti,
            'pisteet', josi.pisteet,
            'siirtynyt_toisesta_valintatapajonosta', josi.siirtynyt_toisesta_valintatapajonosta
        ) as valintatapajonot
    from valinnantulos as vatu
    left join jonosija as josi on vatu.hakemus_hakukohde_valintatapa_id = josi.hakemus_hakukohde_valintatapa_id
    left join jono on vatu.valintatapajono_oid = jono.valintatapajono_oid
),

valintatapajonot as (
    select
        hakutoive_id,
        jsonb_agg(valintatapajonot) as valintatapajonot
    from rivit
    group by
        hakutoive_id
),

paras_jono as (
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
                then 'PERUUNTUNUT'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "HYLATTY")'
                then 'HYLATTY'
            when valintatapajonot @? '$[*] ? (@.valinnan_tila == "KESKEN")'
                then 'KESKEN'
        end as valintatieto
    from valintatapajonot
),

paras_jono_pvm as (
    select distinct on (hakutoive_id)
        hakutoive_id,
        (jonotiedot ->> 'valintatiedon_pvm')::date as valintatiedon_pvm
    from paras_jono,
            lateral jsonb_array_elements(valintatapajonot) as jonotiedot
    where jonotiedot ->> 'valinnan_tila' = valintatieto
    order by
        1, 2 --noqa: AM06
),

final as (
    select
        pajo.hakutoive_id,
        pajo.valintatapajonot,
        pajo.valintatieto,
        pjpv.valintatiedon_pvm,
        case
            when pajo.valintatapajonot @? '$[*] ? (@.ehdollisesti_hyvaksytty==true)'
                then true
            else false
		end as ehdollisesti_hyvaksytty
    from paras_jono as pajo
    left join paras_jono_pvm as pjpv on pajo.hakutoive_id = pjpv.hakutoive_id
)

select * from final
