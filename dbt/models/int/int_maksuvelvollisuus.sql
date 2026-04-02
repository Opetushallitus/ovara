{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}

with hakemus as ( --noqa: PRS
    select * from {{ ref('int_ataru_hakemus') }}
    where kasittelymerkinnat @? '$[*] ? (@.requirement == "payment-obligation")'
),

rows as (
    select hakemus_oid,
        (
            jsonb_path_query(
            kasittelymerkinnat,
            '$[*] ? (@.requirement == "payment-obligation")'
            ) ->> 'hakukohde'
        ) as hakukohde_oid,
        (
            jsonb_path_query(
            kasittelymerkinnat,
            '$[*] ? (@.requirement == "payment-obligation")'
            ) ->> 'state'
        ) as maksuvelvollisuus
    from hakemus
)

select
    {{ hakutoive_id() }},
    maksuvelvollisuus
from rows
