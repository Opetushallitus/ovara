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
    from {{ ref('dw_sure_opiskelija') }}
),

int as (
    select * from raw
    where row_nr = 1
),

final as (
    select
        resourceid,
        oppilaitosoid,
        luokkataso,
        luokka,
        henkilooid,
        alkupaiva,
        loppupaiva,
        muokattu,
        poistettu,
        source
    from int
)

select * from final
