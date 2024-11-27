{{
  config(
    materialized = 'table',
    indexes = [
    {'columns':['parent_oid']}
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
order by 1, 2
