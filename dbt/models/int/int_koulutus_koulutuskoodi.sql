{{
  config(
    indexes=[{'columns': ['oid']}]
)
}}

with raw as (
    select
        oid,
        koulutuksetkoodiuri,
        row_number() over (partition by oid order by muokattu desc) as rownr
    from {{ ref("dw_kouta_koulutus") }}
),

final as (
    select
        oid,
        jsonb_array_elements_text(koulutuksetkoodiuri) as koulutuskoodiuri
    from raw
    where rownr = 1
)

select * from final
