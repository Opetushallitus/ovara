{{
  config(
    materialized = 'view',
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by hakukohde_henkilo_id order by muokattu desc) as row_nr
    from {{ ref('dw_valintarekisteri_hyvaksyttyjulkaistuhakutoive') }}
),

final as (
    select
        hakukohde_henkilo_id,
        hakukohde_oid,
        henkilo_oid,
        hyvaksyttyjajulkaistu
    from raw
    where row_nr = 1
)

select * from final
