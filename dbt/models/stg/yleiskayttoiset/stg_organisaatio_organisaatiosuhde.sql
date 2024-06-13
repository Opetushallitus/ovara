{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['suhdetyyppi','child_oid','parent_oid']}
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'organisaatio_organisaatiosuhde') }}
),

final as (
    select
        data ->> 'suhdetyyppi' as suhdetyyppi,
        data ->> 'parent_oid' as parent_oid,
        data ->> 'child_oid' as child_oid,
        (data ->> 'alkupvm')::timestamptz as alkupvm,
        {{ metadata_columns() }}
    from source
)

select * from final
