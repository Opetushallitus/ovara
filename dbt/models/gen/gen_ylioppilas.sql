{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('henkilo_oid') }}"
    ]
    )
}}
with raw as (
    select * from {{ ref('int_ylioppilas') }}
)

select * from raw