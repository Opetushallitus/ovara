with source as (
    select distinct on (oid) *
    from {{ ref('dw_kouta_oppilaitoksetjaosat') }}
    order by oid asc, muokattu desc
)

select * from source
