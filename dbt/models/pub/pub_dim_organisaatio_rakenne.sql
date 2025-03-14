{{
  config(
    materialized = 'table',
    indexes = [
    {'columns':['parent_oid']},
    {'columns':['child_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_organisaatio_rakenne') }}
)

select
    parent_oid,
    child_oid
from source
order by parent_oid, child_oid
