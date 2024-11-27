{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['parent_oid']}
    ]
    )
}}

with recursive organisaatio as (
    select * from {{ ref('int_organisaatio') }}
),

org (parent_oid, child_oid) as (
    select
        ylempi_organisaatio as parent_oid,
        organisaatio_oid as child_oid
    from organisaatio

    union all

    select
        orga.parent_oid,
        org2.organisaatio_oid as child_oid
    from organisaatio as org2
    inner join org as orga on org2.ylempi_organisaatio = orga.child_oid
),

final as (
    select
        parent_oid,
        child_oid
    from org
    union
    select
        organisaatio_oid as parent_oid,
        organisaatio_oid as child_oid
    from organisaatio
)

select * from final
