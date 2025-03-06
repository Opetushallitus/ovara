{{
  config(
    materialized='table',
    indexes = [
        {'columns': ['hakemus_hakukohde_valintatapa_id']}
    ]
    )
}}

with raw as (
    select distinct on (valinnantulos_id)
        *
    from {{ ref('dw_valintarekisteri_valinnantulos') }}
    order by valinnantulos_id, muokattu desc
),

final as (
    select
        valinnantulos_id,
        {{ hakutoive_id() }},
        {{ dbt_utils.generate_surrogate_key(['hakemus_oid','hakukohde_oid','valintatapajono_oid']) }}
        as hakemus_hakukohde_valintatapa_id,
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
        hyvaksyperuuntunut,
        muokattu::date as valintatiedon_pvm
   from raw
)

select * from final
