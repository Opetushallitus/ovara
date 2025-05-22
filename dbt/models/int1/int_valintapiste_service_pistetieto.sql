with source as (
    select * from {{ ref('dw_valintapiste_service_pistetieto') }}
)

select * from source
