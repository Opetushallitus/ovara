{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid','haku_oid']}
    ]
    )
}}

with haut as (
    select haku_oid from {{ ref('int_sure_haut') }}
),

raw as (
    select
        henkilo_oid,
        haku_oid,
        isensikertalainen,
        menettamisenperuste,
        menettamisenpaivamaara
    from {{ ref('int_sure_ensikertalainen') }} a
    where exists(
        select 1 from haut b where a.haku_oid = b.haku_oid
        )

    union all

    select distinct
        henkilo_oid,
        haku_oid,
        isensikertalainen,
        menettamisen_peruste,
        menettamisen_paivamaara
    from {{ ref('int_supa_ensikertalainen') }} a
    where not exists(
        select 1 from haut b where a.haku_oid = b.haku_oid
        )
)

select * from raw
