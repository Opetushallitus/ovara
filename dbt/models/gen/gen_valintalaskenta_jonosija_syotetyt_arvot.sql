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
        valintatapajono_oid,
        hakemus_oid,
        hakukohde_oid,
        hakija_oid,
        syotetyt_arvot
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
        syar.obj ->> 'arvo' as arvo,
        syar.obj ->> 'tunniste' as tunniste,
        (syar.obj ->> 'tilastoidaan')::boolean as tilastoidaan,
        syar.obj ->> 'osallistuminen' as osallistuminen,
        syar.obj ->> 'laskennallinenArvo' as laskennallinen_arvo
    from jonosijat as josi
    cross join lateral (select jsonb_array_elements(syotetyt_arvot)) as syar(obj)
)

select * from final
