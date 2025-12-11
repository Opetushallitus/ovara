{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['haku_oid']},
        {'columns':['henkilo_oid']},
        {'columns':['hakemus_oid']}

    ]
    )
}}

with hakemus as not materialized (
    select * from {{ ref('int_ataru_hakemus') }}
    where not tila = 'inactivated'
),

suoritus as (
    select
        hakemusoid as hakemus_oid,
        pohjakoulutus
    from {{ ref('int_sure_proxysuoritus') }}
    where pohjakoulutus is not null
),

int as (
    select
        hake.hakemus_oid,
        hake.haku_oid,
        hake.tila,
        hake.henkilo_oid,
        hake.pohjakoulutus_kk,
        hake.pohjakoulutuksen_maa_toinen_aste,
        sure.pohjakoulutus
    from hakemus as hake
    left join suoritus as sure on hake.hakemus_oid = sure.hakemus_oid
)

select * from int
order by haku_oid
