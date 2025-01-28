{{
  config(
    materialized = 'view',
    )
}}
with raw as (
    select
        *,
        row_number() over (partition by haku_oid order by muokattu desc) as row_nr
    from {{ ref('dw_ohjausparametrit_parameter') }}
),

final as (
    select
        haku_oid,
        vastaanotto_paattyy,
        hakijakohtainen_paikan_vastaanottoaika
    from raw where row_nr = 1
)

select * from final
