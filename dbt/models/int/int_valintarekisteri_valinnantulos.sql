{{
  config(
    materialized='table',
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by valinnantulos_id order by muokattu desc) as row_nr
    from {{ ref('dw_valintarekisteri_valinnantulos') }}
),

final as (
    select
        valinnantulos_id,
        {{ hakutoive_id() }},
        hakukohde_oid,
        valintatapajono_oid,
        hakemus_oid,
        henkilo_oid,
        valinnantila as valinnan_tila,
        ehdollisestihyvaksyttavissa as ehdollisesti_hyvaksyttavissa,
        jsonb_build_object(
            'en', ehdollisenhyvaksymisenehtoen,
            'sv', ehdollisenhyvaksymisenehtosv,
            'fi', ehdollisenhyvaksymisenehtofi
        ) as ehdollisen_hyvaksymisen_ehto,
        jsonb_build_object(
            'en', valinnantilankuvauksentekstien,
            'sv', valinnantilankuvauksentekstisv,
            'fi', valinnantilankuvauksentekstifi
        ) as valinnantilan_kuvauksen_teksti,
        julkaistavissa,
        hyvaksyperuuntunut
    from raw where row_nr = 1
)

select * from final
