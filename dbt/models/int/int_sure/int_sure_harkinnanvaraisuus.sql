{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['hakemus_oid','hakukohde_oid']}
        ]
    )
}}

with source as ( -- noqa: PRS
    select * from {{ ref('dw_sure_harkinnanvaraisuus') }} -- noqa: PRS
), -- noqa: PRS

rows as (
     select
        hakemusoid,
        jsonb_array_elements(hakutoiveet) as hakutoive
    from source
),

final as (
    select
        hakemusoid as hakemus_oid,
        hakutoive->>'hakukohdeOid' as hakukohde_oid,
        hakutoive->>'harkinnanvaraisuudenSyy' as harkinnanvaraisuude_syy
    from rows
)

select * from final
