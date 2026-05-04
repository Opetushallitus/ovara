{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['henkilo_oid, hakukohde_oid']}
    ]
  )
}}

with source as (
    select
        {{ dbt_utils.star(
        from=ref('int_hakutoive'),
        except=[
            'hakukohde_henkilo_id',
            'henkilo_hakemus_id',
            'valintatapajonot'
            ]
        )
    }}
    from {{ ref('int_hakutoive') }}
)

select * from source
