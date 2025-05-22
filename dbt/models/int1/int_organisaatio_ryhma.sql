{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohderyhma_oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('dw_organisaatio_ryhma') }}
),

final as (
    select
        oid as hakukohderyhma_oid,
        jsonb_build_object(
            'en', coalesce(nimi_en, nimi_fi, nimi_sv),
            'sv', coalesce(nimi_sv, nimi_fi, nimi_en),
            'fi', coalesce(nimi_fi, nimi_sv, nimi_en)
        ) as hakukohderyhma_nimi
    from raw
)

select * from final
