{{
  config(
    materialized='table',
    indexes = [
        {'columns': ['hakukohde_henkilo_id']}
    ]
    )
}}

with raw as (
    select distinct on (hakukohde_henkilo_id) * from {{ ref('dw_valintarekisteri_lukuvuosimaksu') }}
    order by hakukohde_henkilo_id asc, muokattu desc
),

final as (
    select
        hakukohde_henkilo_id,
        hakukohde_oid,
        henkilo_oid,
        maksun_tila
    from raw
)

select * from final
