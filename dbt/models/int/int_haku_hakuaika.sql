{{
  config(
    indexes=[{'columns': ['hakuaika_id']}]
)
}}

with raw as (
    select
        oid,
        hakuajat,
        row_number() over (partition by oid order by muokattu desc) as rownr
    from {{ ref("dw_kouta_haku") }}
),

int as (
    select
        oid,
        jsonb_array_elements(hakuajat) as hakuaika
    from raw
    where rownr = 1
),

hakuajat as (
    select
        oid,
        (hakuaika ->> 'alkaa')::timestamptz as alkaa,
        (hakuaika ->> 'paattyy')::timestamptz as paattyy
    from int
),

final as (
    select
        md5(
            coalesce(alkaa::varchar, '_dbt_utils_surrogate_key_null_')
            || '-' || coalesce(paattyy::varchar, '_dbt_utils_surrogate_key_null_')
        )::varchar as hakuaika_id,
        oid
    from hakuajat
)

select * from final
