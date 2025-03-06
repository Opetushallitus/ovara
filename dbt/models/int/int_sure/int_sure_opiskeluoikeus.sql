{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select distinct on (resourceid) * from {{ ref('dw_sure_opiskeluoikeus') }}
    order by resourceid asc, muokattu desc
),

final as (
    select
        resourceid,
        alkupaiva,
        loppupaiva,
        henkilooid,
        komo,
        myontaja,
        source,
        muokattu,
        poistettu
    from raw
)

select * from final
