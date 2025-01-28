{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['hakutoive_id']}
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

int as (
    select
        hakemusoid as hakemus_oid,
        hakutoive->>'hakukohdeOid' as hakukohde_oid,
        hakutoive->>'harkinnanvaraisuudenSyy' as harkinnanvaraisuuden_syy
    from rows
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
                ['hakemus_oid',
                'hakukohde_oid']
            ) }} as hakutoive_id,
        *
    from int
)

select * from final
