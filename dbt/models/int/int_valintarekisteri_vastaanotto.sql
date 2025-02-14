{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_henkilo_id']}
    ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by hakukohde_henkilo_id order by muokattu desc) as row_nr
    from {{ ref('dw_valintarekisteri_vastaanotto') }}
),

final as (
    select
        hakukohde_henkilo_id,
        selite,
        operaatio as vastaanottotieto
    from raw
    where row_nr = 1
)

select * from final
