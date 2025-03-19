{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}
with maksuvelvollisuus as (
    select * from {{ ref('int_maksuvelvollisuus') }}
)

select * from maksuvelvollisuus
