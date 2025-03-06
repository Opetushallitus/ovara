{{
  config(
    materialized = 'view',
    )
}}
with raw as (
    select distinct on (haku_oid)
        *
    from {{ ref('dw_ohjausparametrit_parameter') }}
    order by haku_oid, muokattu desc
),

final as (
    select
        haku_oid,
        vastaanotto_paattyy,
        hakijakohtainen_paikan_vastaanottoaika
    from raw
)

select * from final
