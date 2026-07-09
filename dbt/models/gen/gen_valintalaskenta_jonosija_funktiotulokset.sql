{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakemus_oid']},
        {'columns': ['hakija_oid']}
    ]
    )
}}

with jonosijat as (
    select
        valinnanvaihe_id,
        valintatapajono_nimi,
        hakemus_oid,
        hakija_oid,
        funktiotulokset
    from {{ ref('int_valintalaskenta_jonosijat') }}
),

final as (
    select
        josi.valinnanvaihe_id,
        josi.valintatapajono_nimi,
        josi.hakemus_oid,
        josi.hakija_oid,
        futo.obj ->> 'arvo' as arvo,
        futo.obj ->> 'tunniste' as tunniste,
        futo.obj ->> 'nimiFi' as nimi_fi,
        futo.obj ->> 'nimiSv' as nimi_sv,
        futo.obj ->> 'nimiEn' as nimi_en,
        (futo.obj ->> 'omaopintopolku')::boolean as omaopintopolku
    from jonosijat as josi
    cross join lateral (select jsonb_array_elements(funktiotulokset)) as futo(obj)
)

select * from final
