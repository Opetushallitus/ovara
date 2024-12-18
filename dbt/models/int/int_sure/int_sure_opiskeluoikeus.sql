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
    from {{ ref('dw_sure_opiskeluoikeus') }}
),

int as (
    select * from raw
    where row_nr = 1
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
    from int
)

select * from final
