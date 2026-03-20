{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_oid']}
    ]
    )
}}

{% set table = 'int_valintarekisteri_valinnantulos' %}

with raw as (
    select
        {{ dbt_utils.star(from=ref(table),except=['valinnantulos_id']) }}
    from {{ ref(table) }}
)

select * from raw
