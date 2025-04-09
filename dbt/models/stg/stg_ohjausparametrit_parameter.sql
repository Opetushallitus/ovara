with source as (
    select * from {{ source('ovara', 'ohjausparametrit_parameter') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'key' as haku_oid,
        (data ->> 'lastModified')::timestamptz as muokattu,
        to_timestamp((data -> 'values' -> 'PH_OPVP' ->> 'date')::bigint / 1000)::timestamptz as vastaanotto_paattyy,
        (data -> 'values' -> 'PH_HPVOA' ->> 'value')::int as hakijakohtainen_paikan_vastaanottoaika,
        (data -> 'values' ->> 'sijoittelu')::bool as sijoittelu,
        (data -> 'values' ->> 'useitaHakemuksia')::bool as useita_hakemuksia,
        (data -> 'values' ->> 'jarjestetytHakutoiveet')::bool as jarjestetyt_hakutoiveet,
        (data -> 'values' ->> 'hakutoiveidenEnimmaismaara')::int as hakutoiveiden_enimmaismaara,
        (data -> 'values' ->> 'hakutoiveidenMaaraRajoitettu')::bool as hakutoiveiden_maara_rajoitettu,
        (data -> 'values')::jsonb as arvot,
        {{ metadata_columns() }}
    from source
)

select * from final
