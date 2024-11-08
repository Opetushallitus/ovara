{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['hakemus_oid','hakukohde_oid']}
        ]
    )
}}

with source as (
    select * from {{ref('dw_sure_harkinnanvaraisuudet') }}
),

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
