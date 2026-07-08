{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('tunniste') }}"
    ]
    )
}}

select * from {{ ref('int_opiskeluoikeus_kk') }}
