{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['oid']}
        ]
    )
}}

with source as (
    select * from {{ source('ovara', 'organisaatio_ryhma') }}
),

final as (
    select
        data ->> 'oid' as oid,
        data ->> 'nimiFi' as nimi_fi,
        data ->> 'nimiSv' as nimi_sv,
        data ->> 'nimiEn' as nimi_en,
        {{ metadata_columns() }}
    from source
)

select * from final
