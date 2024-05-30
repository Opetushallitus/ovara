{{
  config(
    materialized = 'view'
    )
}}

select * from {{ ref('stg_organisaatio_osoite') }}
