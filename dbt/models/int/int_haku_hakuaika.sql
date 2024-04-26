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
        oid,
        md5(
            (
                coalesce(alkaa::text, '_dbt_utils_surrogate_key_null_')
                || '-'
                || coalesce(paattyy::text, '_dbt_utils_surrogate_key_null_')
            )::text
        ) as hakuaika_id

    from hakuajat
)

select * from final
