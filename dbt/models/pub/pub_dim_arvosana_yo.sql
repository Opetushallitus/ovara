{{
    config(
        materialized = 'table',
    )
}}

with arvosana as (
    select * from {{ ref('int_arvosana_yo') }}
)

select * from arvosana
