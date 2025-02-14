{{
  config(
    materialized = 'incremental',
    unique_key = 'henkilo_oid',
    incremental_strategy = 'merge',
    indexes = [
        {'columns': ['henkilo_oid','master_oid']},
        {'columns':['henkilo_oid','kansalaisuus']},
        {'columns':['muokattu']}
    ]
    )
}}

with raw as (
    select * from {{ ref('dw_onr_henkilo') }}
    {% if is_incremental() %}
        where muokattu > coalesce((select max(muokattu) from {{ this }}), date('1900-01-01'))
    {% endif %}

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
