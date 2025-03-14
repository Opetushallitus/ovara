{{
  config(
    materialized = 'table',
    )
}}

with arvosana as (
    select * from {{ ref('int_sure_arvosana') }} where asteikko = 'YO'
),

suoritus as (
    select * from {{ ref('int_sure_suoritus') }}
),

rivi as (
    select
        suoritus,
        jsonb_object_agg(yo_aine, arvosana) as arvosanat
    from arvosana
    group by suoritus
),

final as (
    select
        suor.henkilo_oid,
        rivi.arvosanat
    from suoritus as suor
    inner join rivi on suor.resourceid = rivi.suoritus
)

select distinct * from final
