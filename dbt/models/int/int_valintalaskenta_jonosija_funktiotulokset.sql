{{
  config(
    materialized = 'incremental',
    unique_key= 'valinnanvaihe_id',
    incremental_strategy = 'delete+insert',
    indexes = [
        {'columns': ['dw_metadata_dw_stored_at']},
        {'columns': ['valinnanvaihe_id']}
    ]
    )
}}

with jonosijat as (
    select
        valinnanvaihe_id,
        valintatapajono_oid,
        valintatapajono_nimi,
        hakukohde_oid,
        hakemus_oid,
        hakija_oid,
        funktiotulokset,
        dw_metadata_dw_stored_at
    from {{ ref('int_valintalaskenta_jonosijat') }}
),

final as (
    select
        josi.valinnanvaihe_id,
        josi.valintatapajono_oid,
        josi.valintatapajono_nimi,
        josi.hakemus_oid,
        josi.hakukohde_oid,
        josi.hakija_oid,
        futo.obj ->> 'arvo' as arvo,
        futo.obj ->> 'tunniste' as tunniste,
        futo.obj ->> 'nimiFi' as nimi_fi,
        futo.obj ->> 'nimiSv' as nimi_sv,
        futo.obj ->> 'nimiEn' as nimi_en,
        (futo.obj ->> 'omaopintopolku')::boolean as omaopintopolku,
        dw_metadata_dw_stored_at
    from jonosijat as josi
    cross join lateral (select jsonb_array_elements(funktiotulokset)) as futo(obj)
)

select * from final
