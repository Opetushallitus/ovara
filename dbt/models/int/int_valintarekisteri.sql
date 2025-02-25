{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_henkilo_id']}
    ]
    )
}}

with vastaanotto as (
    select * from {{ ref('int_valintarekisteri_vastaanotto') }}
),

ilmoittautuminen as (
    select * from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

final as (
    select
        coalesce(vast.hakukohde_henkilo_id, ilmo.hakukohde_henkilo_id) as hakukohde_henkilo_id,
        vast.vastaanottotieto,
        ilmo.tila as ilmoittautumisen_tila
    from vastaanotto as vast
    full outer join ilmoittautuminen as ilmo on vast.hakukohde_henkilo_id = ilmo.hakukohde_henkilo_id
)

select * from final
