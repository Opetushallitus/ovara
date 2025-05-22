with source as (
    select distinct on (hakemusoid) *
    from {{ ref('dw_valintalaskenta_valintakoe_osallistuminen') }}
    order by hakemusoid asc, muokattu desc
)

select * from source
