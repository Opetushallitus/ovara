{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohderyhma_oid']}
        ]
    )
}}

with raw as (
    select
        *,
        coalesce(nimi_fi, nimi_sv, nimi_en) as nimi_fi_new,
        coalesce(nimi_sv, nimi_fi, nimi_en) as nimi_sv_new,
        coalesce(nimi_en, nimi_fi, nimi_sv) as nimi_en_new
    from {{ ref('dw_organisaatio_ryhma') }}
),

final as (
    select
        oid as hakukohderyhma_oid,
        jsonb_build_object(
            'en', nimi_en_new,
            'sv', nimi_sv_new,
            'fi', nimi_fi_new
        ) as hakukohderyhma_nimi
    from raw
)

select * from final
