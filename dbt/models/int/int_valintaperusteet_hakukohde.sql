with raw as (
    select distinct on (hakukohde_oid) * from {{ ref('dw_valintaperusteet_hakukohde') }}
    order by hakukohde_oid asc, muokattu desc
)

select * from raw
