with organisaatio as (
    select distinct on (organisaatio_oid) * from {{ ref('dw_organisaatio_organisaatio') }}
    order by organisaatio_oid asc, muokattu desc
)

select * from organisaatio
