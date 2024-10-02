{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid','master_oid']},
        {'columns':['henkilo_oid','kansalaisuus']}
    ]
    )
}}

with raw as (
    select * from {{ ref('dw_onr_henkilo') }}
),

final as (
    select
        henkilo_oid,
        coalesce(master_oid, henkilo_oid) as master_oid,
        master_oid is null as master,
        {{ dbt_utils.star(from=ref('dw_onr_henkilo'), except=['henkilo_oid', 'master_oid']) }}
    from raw
)

select * from final
