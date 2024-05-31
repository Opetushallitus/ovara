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
        {{ dbt_utils.star(from=ref('dw_ataru_hakemus')) }}
    from raw
    where
        row_nr = 1
        and henkilo_oid is not null
)

select * from final
