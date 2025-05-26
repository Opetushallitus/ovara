with source as (
    select
        distinct on (valintakoe_hakemus_id)
        *
    from {{ ref('dw_valintapiste_service_pistetieto') }}
    order by valintakoe_hakemus_id asc, muokattu desc
)

select * from source
