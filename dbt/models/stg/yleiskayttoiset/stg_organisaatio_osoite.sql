{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['organisaatio_oid','kieli','osoitetyyppi']}
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'organisaatio_osoite') }}
),

raw as (
    select
        data ->> 'organisaatio_oid' as organisaatio_oid,
        data ->> 'kieli' as kieli,
        data ->> 'osoitetyyppi' as osoitetyyppi,
        data ->> 'osoite' as osoite,
        data ->> 'postinumero' as postinumero,
        data ->> 'postitoimipaikka' as postitoimipaikka,
        {{ metadata_columns() }}
    from source
)

select *  from raw
