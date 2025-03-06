{{
  config(
    materialized = 'view',
    )
}}

with raw as (
    select distinct on (hakukohde_henkilo_id)
        *
    from {{ ref('dw_valintarekisteri_hyvaksyttyjulkaistuhakutoive') }}
    order by hakukohde_henkilo_id, muokattu desc
),

final as (
    select
        hakukohde_henkilo_id,
        hakukohde_oid,
        henkilo_oid,
        hyvaksyttyjajulkaistu
    from raw
)

select * from final
