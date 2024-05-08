{{
  config(
    indexes=[{'columns':['oid','kansalaisuus']}]
    )
}}

with raw as (
    select
        oid,
        kansalaisuus,
        muokattu,
        row_number () over (partition by oid, versio_id order by muokattu desc) as _row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

final as (
    select
        oid,
        (jsonb_array_elements(kansalaisuus)->>0)::int as kansalaisuus,
        muokattu
    from raw where _row_nr = 1
)

select * from final

