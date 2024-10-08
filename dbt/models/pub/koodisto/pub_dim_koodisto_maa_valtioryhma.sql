{{
        config (
        materialized='table',
        indexes = [
            {'columns': ['maa_koodiarvo']}
        ]
    )
}}

with raw as (
    select * from {{ ref('int_koodisto_maa_valtioryhma') }}
),

max_rel as (
    select
        *,
        max(relaatioversio) over (partition by maa_koodiarvo, valtioryhma_koodiarvo) as max_rel
    from raw
),

final as (
    select
        {{ dbt_utils.star(from=ref('int_koodisto_maa_valtioryhma'), except=['relaatioversio']) }}
    from max_rel
    where max_rel = relaatioversio
)

select * from final
