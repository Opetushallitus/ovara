{{
  config(
    materialized = 'table',
    )
}}

with arvosana as (
    select
        suoritus,
        yo_aine,
        arvosana
    from {{ ref('int_sure_arvosana') }}
    where asteikko = 'YO'
),

suoritus as (
    select
        resourceid,
        henkilo_oid
    from {{ ref('int_sure_suoritus') }}
    where not poistettu
),

final as (
    select
        suor.henkilo_oid,
        rivi.arvosanat
    from suoritus as suor
    inner join (
        select
            suoritus,
            jsonb_object_agg(yo_aine, arvosana) as arvosanat
        from arvosana
        group by suoritus
    ) as rivi on suor.resourceid = rivi.suoritus
)

select * from final
