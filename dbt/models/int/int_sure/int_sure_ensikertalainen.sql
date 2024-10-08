{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with int as (
    select
        *
    from {{ ref('dw_sure_ensikertalainen') }}
),

final as (
    select
        hakuoid,
        henkilooid,
        isensikertalainen,
        menettamisenperuste,
        menettamisenpaivamaara
    from int
)

select * from final
