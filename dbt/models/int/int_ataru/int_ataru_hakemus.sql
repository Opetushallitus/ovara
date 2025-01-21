{{
  config(
    materialized = 'view',
    )
}}

with raw as not materialized(
    select
        *,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

final as (
    select
        oid as hakemus_oid,
        {{ dbt_utils.star(from=ref('dw_ataru_hakemus'),except = ['oid']) }}
    from raw
    where
        row_nr = 1
        and henkilo_oid is not null
)

select * from final
