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
        jarjestyskriteerit
    from {{ ref('int_valintalaskenta_jonosijat') }}
),

final as (
    select
        josi.valinnanvaihe_id,
        josi.valintatapajono_nimi,
        josi.hakemus_oid,
        josi.hakija_oid,
        jaki.obj ->> 'arvo' as arvo,
        jaki.obj ->> 'nimi' as nimi,
        jaki.obj -> 'tila' as tila,
        jaki.obj -> 'kuvaus' ->> 'FI' as kuvaus_fi,
        jaki.obj -> 'kuvaus' ->> 'SV' as kuvaus_sv,
        jaki.obj -> 'kuvaus' ->> 'EN' as kuvaus_en,
        jaki.obj -> 'prioriteetti' as prioriteetti
    from jonosijat as josi
    cross join lateral (select jsonb_array_elements(jarjestyskriteerit)) as jaki(obj)
)

select * from final
