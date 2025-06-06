{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_henkilo_id']}
    ]
    )
}}

with raw as (
    select * from {{ ref('int_valintarekisteri_vastaanotto') }}
    order by hakukohde_henkilo_id asc, muokattu desc
),

final as (
    select
        hakukohde_henkilo_id,
        selite,
        operaatio as vastaanottotieto
    from raw
)

select * from final
