{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_oid']}
    ],
    post_hook = [
        "{{ disable_autovacuum_if_not_incremental() }};",
        "{{ create_pk('hakemus_hakukohde_valintatapa_id') }};"
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
