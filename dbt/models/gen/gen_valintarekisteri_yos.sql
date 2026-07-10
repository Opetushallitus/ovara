{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_valintarekisteri_yos') }}
),

final as (
    select
    {{ dbt_utils.star(
        from=ref('int_valintarekisteri_yos'),
        except=['hakutoive_id' ]
    )}}
    from source
)

select * from final
