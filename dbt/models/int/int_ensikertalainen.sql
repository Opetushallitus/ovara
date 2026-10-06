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
    from {{ ref('int_sure_ensikertalainen') }} as a
    where
        exists (
            select 1 from haut
            where a.haku_oid = haut.haku_oid
        )

    union all

    select distinct
        henkilo_oid,
        haku_oid,
        isensikertalainen,
        menettamisen_peruste,
        menettamisen_paivamaara
    from {{ ref('int_supa_ensikertalainen') }} as a
    where
        not exists (
            select 1 from haut
            where a.haku_oid = haut.haku_oid
        )
)

select * from raw
