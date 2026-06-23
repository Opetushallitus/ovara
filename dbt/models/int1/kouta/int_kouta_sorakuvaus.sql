with source as (
    select distinct on (id) *
    from {{ ref('dw_kouta_sorakuvaus') }}
    order by id asc, muokattu desc
)

select * from source
