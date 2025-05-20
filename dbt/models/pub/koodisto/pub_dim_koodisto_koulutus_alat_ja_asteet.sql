{{
    config (
        materialized='table',
        indexes = [
            {'columns': ['koodiarvo']},
        ]
    )
}}

select * from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
