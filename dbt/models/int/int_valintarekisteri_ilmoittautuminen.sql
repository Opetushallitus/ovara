{{
  config(
    materialized='view'
    )
}}

with raw as not materialized (
    select
        *,
        row_number() over (partition by ilmoittautuminen_id order by muokattu desc) as row_nr
    from {{ ref('dw_valintarekisteri_ilmoittautuminen') }}
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
    where row_nr = 1
)

select * from final
