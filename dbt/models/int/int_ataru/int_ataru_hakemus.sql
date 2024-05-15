{{
  config(
    materialized = 'view',
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

final as (
    select
        {{ dbt_utils.star(from=ref('dw_ataru_hakemus'), except=['row-nr','_row_nr']) }}
    from raw
    where row_nr = 1
)

select * from final
