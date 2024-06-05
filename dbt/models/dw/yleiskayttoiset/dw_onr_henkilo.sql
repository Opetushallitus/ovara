{{
  config(
    materialized = 'view'
    )
}}

select * from {{ ref('stg_onr_yhteystieto') }}
