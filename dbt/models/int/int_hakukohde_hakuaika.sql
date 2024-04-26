{{
  config(
    indexes=[{'columns': ['hakuaika_id']}]
)
}}

with raw as (
    select
        oid,
        jsonb_array_elements(hakuajat) as hakuaika
    from {{ ref('dw_kouta_hakukohde') }}
),

hakuajat as (
    select
        oid,
        (hakuaika ->> 'alkaa')::timestamptz as alkaa,
        (hakuaika ->> 'paattyy')::timestamptz as paattyy
    from raw
),

final as (
    select
        md5(
            coalesce(alkaa::varchar, '_dbt_utils_surrogate_key_null_')
            || '-' || coalesce(paattyy::varchar, '_dbt_utils_surrogate_key_null_')::varchar
        ) as hakuaika_id,
        oid
    from hakuajat
)

select * from final
