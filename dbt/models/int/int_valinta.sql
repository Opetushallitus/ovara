{{
  config(
    indexes = [
        {'columns': ['hakutoive_id']}
    ]
    )
}}

with raw as (
    select * from {{ ref('int_valintarekisteri_valinnantulos') }}
),

valintatapajonot as (
    select
        hakutoive_id,
        jsonb_build_object(
            'valintatapajono_oid',valintatapajono_oid,
            'valinnan_tila',valinnan_tila,
            'ehdollisesti_hyvaksyttavissa',ehdollisesti_hyvaksyttavissa,
            'ehdollisen_hyvaksymisen_ehto',ehdollisen_hyvaksymisen_ehto,
            'valinnantilan_kuvauksen_teksti',valinnantilan_kuvauksen_teksti,
            'julkaistavissa',julkaistavissa,
            'hyvaksyperuuntunut',hyvaksyperuuntunut
        ) as valintatapajonot
    from raw
 )

 select
     hakutoive_id,
    jsonb_agg(valintatapajonot) as valintatapajonot
 from valintatapajonot
 group by 1