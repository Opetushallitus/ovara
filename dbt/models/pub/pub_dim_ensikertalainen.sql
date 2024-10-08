{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['hakuoid']},
            {'columns':['henkilooid']},
        ]
    )
}}

with ensikertalainen as (
    select * from {{ ref('int_sure_ensikertalainen') }}
),

int as (
    select
        hakuoid,
        henkilooid,
        isensikertalainen,
        menettamisenperuste,
        menettamisenpaivamaara
    from ensikertalainen 
)

select * from int