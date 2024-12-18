{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by resourceid order by muokattu desc) as row_nr
    from {{ ref('dw_sure_suoritus') }}
),

int as (
    select * from raw
    where row_nr = 1
),

final as (
    select
        resourceid,
        komo,
        myontaja,
        tila,
        valmistuminen,
        henkilooid,
        yksilollistaminen,
        suorituskieli,
        muokattu,
        poistettu,
        source,
        vahvistettu,
        arvot
    from int
)

select * from final
