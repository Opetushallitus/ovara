{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakutoive_id']}
    ]
    )
}}

with valintatapajonot as (
    select * from {{ ref('int_hakutoive_valintatapajono') }}
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
        lateral jsonb_array_elements(valintatapajonot) as jonotiedot --noqa: AL05
    where jonotiedot ->> 'valinnan_tila' = valintatieto
    order by --noqa: AM06
        1, 2
),

final as (
    select
        pajo.hakutoive_id,
        pajo.valintatapajonot,
        pajo.valintatieto,
        pjpv.valintatiedon_pvm,
        pajo.valintatapajonot @? '$[*] ? (@.ehdollisesti_hyvaksytty==true)' as ehdollisesti_hyvaksytty
    from paras_jono as pajo
    left join paras_jono_pvm as pjpv on pajo.hakutoive_id = pjpv.hakutoive_id
)

select * from final
