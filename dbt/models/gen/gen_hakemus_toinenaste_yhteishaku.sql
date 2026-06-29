{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('hakemus_oid') }}"
    ]
    )
}}
with source as (
    select * from {{ ref('int_hakemus_toinenaste_yhteishaku') }}
)

select * from source
