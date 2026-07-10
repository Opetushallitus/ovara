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
        paat.obj ->> 'organisaatioOid' as organisaatio_oid,
        paat.obj -> 'supaNimi' ->> 'fi' as supa_nimi_fi,
        paat.obj -> 'supaNimi' ->> 'sv' as supa_nimi_sv,
        paat.obj -> 'supaNimi' ->> 'en' as supa_nimi_en,
        paat.obj -> 'virtaNimi' ->> 'fi' as virta_nimi_fi,
        paat.obj -> 'virtaNimi' ->> 'sv' as virta_nimi_sv,
        paat.obj -> 'virtaNimi' ->> 'en' as virta_nimi_en,
        muokattu
    from source as yois
    cross join lateral (select jsonb_array_elements(paatettavat_oikeudet)) as paat(obj)
)

select * from final