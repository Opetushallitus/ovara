{{
  config(
    materialized='view'
    )
}}

with raw as (
    select *,
    row_number() over (partition by valinnantulos_id order by muokattu desc ) as row_nr
    from {{ ref('dw_valintarekisteri_valinnantulos') }}
),

final as (
    select
        valinnantulos_id,
        hakukohde_oid,
        valintatapajono_oid,
        hakemus_oid,
        henkilo_oid,
        valinnantila,
        ehdollisestihyvaksyttavissa,
        jsonb_build_object(
            'en', raw.ehdollisenhyvaksymisenehtoen,
            'sv', raw.ehdollisenhyvaksymisenehtosv,
            'fi', raw.ehdollisenhyvaksymisenehtofi
        ) as ehdollisenhyvaksymisenehto,
        jsonb_build_object(
            'en', raw.valinnantilankuvauksentekstien,
            'sv', raw.valinnantilankuvauksentekstisv,
            'fi', raw.valinnantilankuvauksentekstifi
        ) as valinnantilankuvauksenteksti,
        julkaistavissa,
        hyvaksyperuuntunut
    from raw where row_nr = 1
)

select * from final
