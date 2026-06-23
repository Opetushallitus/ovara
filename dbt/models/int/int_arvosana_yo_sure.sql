{{
  config(
    materialized = 'table',
    post_hook = "{{ create_pk('henkilo_oid')}}"
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

onr as (
    select
        henkilo_oid,
        master_oid
    from {{ ref('int_onr_henkilo') }}
),

suoritus as (
    select
        resourceid,
        henkilo_oid
    from {{ ref('int_sure_suoritus') }}
    where not poistettu
),

arvosanat as (
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
    group by
        suor.henkilo_oid,
        rivi.arvosanat
),

arvosanat_master as (
    select
        onr1.master_oid,
        arsa.arvosanat
    from arvosanat as arsa
    join onr as onr1 on arsa.henkilo_oid=onr1.henkilo_oid
),

final as (
    select
        onr1.henkilo_oid,
        arma.arvosanat
    from arvosanat_master arma
    join onr onr1 on arma.master_oid=onr1.master_oid
)

select * from final
