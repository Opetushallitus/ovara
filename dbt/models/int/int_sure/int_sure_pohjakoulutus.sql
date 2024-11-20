{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['hakemus_oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('dw_sure_proxysuoritus') }} where pohjakoulutus is not null
),

final as (
    select
        hakemusoid as hakemus_oid,
        pohjakoulutus
    from raw
)

select * from final
