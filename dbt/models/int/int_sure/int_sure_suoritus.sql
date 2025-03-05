{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select distinct on (resourceid)
        *
    from {{ ref('dw_sure_suoritus') }}
    order by resourceid, muokattu desc
),

final as (
    select
        resourceid,
        komo,
        myontaja,
        tila,
        valmistuminen,
        henkilooid as henkilo_oid,
        yksilollistaminen,
        suorituskieli,
        muokattu,
        poistettu,
        source,
        vahvistettu,
        arvot
    from raw
)

select * from final
