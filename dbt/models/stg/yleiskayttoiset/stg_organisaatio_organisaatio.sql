{{
  config(
    materialized = 'table',
    )
}}

with source as (
    select * from {{ source('ovara', 'organisaatio_organisaatio') }}
),

final as (
    select
        data ->> 'organisaatio_oid' as organisaatio_oid,
        (data ->> 'alkupvm')::timestamptz as alkupvm,
        data ->> 'nimi_fi' as nimi_fi,
        data ->> 'nimi_sv' as nimi_sv,
        data ->> 'organisaatiotyypit' as organisaatiotyypit,
        (data ->> 'paivityspvm')::timestamptz as muokattu,
        data ->> 'tila' as tila,
        {{ metadata_columns() }}
    from source
)

select * from final
