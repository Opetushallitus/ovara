{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with int as (
    select * from {{ ref('dw_sure_ensikertalainen') }}
),

final as (
    select
        hakuoid as haku_oid,
        henkilooid as henkilo_oid,
        isensikertalainen,
        menettamisenperuste,
        menettamisenpaivamaara
    from int
)

select * from final
