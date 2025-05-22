with source as (
    select distinct on (oid) *
    from {{ ref('dw_hakukohderyhmapalvelu_ryhma') }}
    order by oid asc, muokattu desc
)

select * from source
