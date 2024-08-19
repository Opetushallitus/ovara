{{
        config (
        materialized='view'
    )
}}

select * from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
