{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('henkilo_oid') }}"
    ]
    )
}}
with supa as (
    select * from {{ ref('int_arvosana_yo_supa') }}
),

sure as (
    select * from {{ ref('int_arvosana_yo_sure') }}
),

final as (
    select
        *,
        'supa' as lahde
    from supa

    union all

    select
        *,
        'sure' from
    sure b
    where not exists (
        select 1 from supa a where a.henkilo_oid=b.henkilo_oid
    )
)

select * from final