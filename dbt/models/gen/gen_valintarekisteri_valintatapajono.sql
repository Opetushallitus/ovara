{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with source as (
    select
        valintatapajono_oid as valintatapajono_id,
        {{ dbt_utils.star(from=ref('int_valintarekisteri_valintatapajono'), except=['valintatapajono_oid']) }}
    from {{ ref('int_valintarekisteri_valintatapajono') }}
)

select * from source
