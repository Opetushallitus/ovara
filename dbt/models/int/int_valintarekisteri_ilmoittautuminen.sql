{{
  config(
    materialized='table',
    indexes = [
        {'columns': ['hakukohde_henkilo_id']}
    ]
    )
}}

with raw as (
    select distinct on (ilmoittautuminen_id)
        *
    from {{ ref('dw_valintarekisteri_ilmoittautuminen') }}
    order by ilmoittautuminen_id, muokattu desc
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
        ['hakukohde_oid',
        'henkilo_oid']
        ) }} as hakukohde_henkilo_id,
        ilmoittautuminen_id,
        hakukohde_oid,
        henkilo_oid,
        ilmoittaja,
        selite,
        tila
    from raw
 )

select * from final
