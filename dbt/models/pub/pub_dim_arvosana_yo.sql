{{
    config(
        materialized = 'table',
        post_hook= [
            " {{ create_pk('henkilo_oid') }}"
        ]
    )
}}

with arvosana as (
    select * from {{ ref('int_arvosana_yo') }}
)

select * from arvosana
