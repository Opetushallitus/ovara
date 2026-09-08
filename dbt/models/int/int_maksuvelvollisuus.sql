{{
  config(
    materialized = 'table',
    unlogged = true,
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}

with kk_haku as (
    select haku_oid from {{ ref('int_kouta_haku') }}
    where haun_tyyppi = 'korkeakoulu'
),


hakemus as ( --noqa: PRS
    select * from {{ ref('int_ataru_hakemus') }} as hake
    where exists (select 1 from kk_haku as haku where hake.haku_oid=haku.haku_oid )
),

rows as (
    select
        hake.hakemus_oid,
        merk.merkinta ->> 'hakukohde' as hakukohde_oid,
        merk.merkinta ->> 'state' as maksuvelvollisuus
    from hakemus as hake
    left join lateral (
        select jsonb_path_query(
            hake.kasittelymerkinnat,
            '$[*] ? (@.requirement == "payment-obligation")'
        ) as merkinta
    ) as merk on true
)

select
    {{ hakutoive_id() }},
    maksuvelvollisuus
from rows
where hakukohde_oid is not null
