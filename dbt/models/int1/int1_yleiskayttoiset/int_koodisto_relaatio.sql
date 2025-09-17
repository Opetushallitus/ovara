{{
  config(
    indexes=[
        {'columns':['ylakoodiarvo','ylakoodiversio']},
        {'columns':['alakoodiarvo','alakoodiversio']},
    ]
    )
}}

with source as (
    select * from {{ ref('dw_koodisto_relaatio') }}
)

select * from source
