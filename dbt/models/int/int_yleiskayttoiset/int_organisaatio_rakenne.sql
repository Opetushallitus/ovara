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
    inner join org as orga on orga.child_oid = org2.ylempi_organisaatio
)

select
    parent_oid,
    child_oid
from org
