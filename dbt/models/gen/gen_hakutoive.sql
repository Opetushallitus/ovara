{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['henkilo_oid, hakukohde_oid']}
    ],
    post_hook = [
        "{{ create_pk('hakutoive_id') }}"
    ]
  )
}}

with hakutoive as (
    select
        {{ dbt_utils.star(
        from=ref('int_hakutoive'),
        except=[
            'hakukohde_henkilo_id',
            'henkilo_hakemus_id',
            'valintatapajonot'
            ]
        )
    }}
    from {{ ref('int_hakutoive') }}
),

haut as (
    select haku_oid from {{ ref('int_sure_haut') }}
),

osallistui as (
    select
        hakutoive_id,
        osallistui_paasykoe,
        osallistui_lisanaytto
    from {{ ref('int_hakutoive_paasykoe_osallistui') }}
),

final as (
    select
        hato.*,
        coalesce(osal.osallistui_paasykoe,false) as osallistui_paasykoe,
        coalesce(osal.osallistui_lisanaytto,false) as osallistui_lisanaytto,
        case when haut.haku_oid is null then 'sure' else 'supa' end as jarjestelma
    from hakutoive as hato
    left join haut on hato.haku_oid=haut.haku_oid
    left join osallistui as osal on hato.hakutoive_id = osal.hakutoive_id
)

select * from final
