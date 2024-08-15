{{
        config (
        materialized='table',
        indexes = [
            {'columns': ['kunta_koodiarvo']}
        ]
    )
}}

with raw as (
    select * from {{ ref('int_koodisto_kunta_maakunta') }}
),

max_rel as (
    select
        *,
        max (relaatioversio) over (partition by kunta_koodiarvo,maakunta_koodiarvo) as max_rel
    from raw
),

final as (
select
    {{ dbt_utils.star(from=ref('int_koodisto_kunta_maakunta'), except = ['relaatioversio']) }}
from max_rel
where max_rel=relaatioversio
)

select * from final
