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

with source as (
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

final as (
    select
        a.*,
        case when b.haku_oid is null then 'sure' else 'supa' end as jarjestelma
    from source as a
    left join haut b on a.haku_oid=b.haku_oid
)

select * from final
