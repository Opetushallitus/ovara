{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}
with source as (
    select * from {{ ref('int_valintarekisteri_yhdenopiskeluoikeudensaados') }}
),

final as (
    select
        yois.henkilo_oid,
        yois.hakutoive_id,
        yois.hakemus_oid,
        yois.hakukohde_oid,
        yois.paatelty_aloituspvm,
        paat.obj ->> 'virtaOpiskeluOikeusId' as virta_opiskeluikeus_id,
        yois.muokattu
    from source as yois
    cross join lateral (select jsonb_array_elements(paatettavat_oikeudet)) as paat(obj)
)

select * from final