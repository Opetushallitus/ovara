{{
  config(
    indexes=[{'columns': ['oid']}]
)
}}

with raw as (
    select distinct on (oid)
        oid,
        koulutuksetkoodiuri
    from {{ ref("dw_kouta_koulutus") }}
    order by oid, muokattu desc
),

final as (
    select
        oid,
        jsonb_array_elements_text(koulutuksetkoodiuri) as koulutuskoodiuri,
        split_part(
            split_part(
                jsonb_array_elements_text(koulutuksetkoodiuri), '_', 2
            ), '#', 1
        ) as koulutuskoodiarvo
    from raw
)

select * from final
