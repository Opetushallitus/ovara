{{
  config(
    indexes=[
        {'columns':['ylakoodiuri','ylakoodiversio']},
        {'columns':['alakoodiuri','alakoodiversio']},
    ]
    )
}}

with source as (
    select * from {{ ref('dw_koodisto_relaatio') }}
)

select * from source
