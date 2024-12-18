with source as (
    select * from {{ source('ovara', 'sure_opiskelija') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'resourceId'::varchar as resourceid,
        data ->> 'oppilaitosOid'::varchar as oppilaitosoid,
        data ->> 'luokkataso'::varchar as luokkataso,
        data ->> 'luokka'::varchar as luokka,
        data ->> 'henkiloOid'::varchar as henkilooid,
        --to_timestamp((data ->> ('alkuPaiva')::varchar)::bigint /1000 ) as alkupaiva,
        ((
            to_timestamp(((data ->> ('alkuPaiva')::varchar)::bigint / 1000)) at time zone 'utc'
            at time zone 'europe/helsinki'
        )::timestamptz) as alkupaiva,
        --to_timestamp((data ->> ('loppuPaiva')::varchar)::bigint /1000 ) as loppupaiva,
        ((
            to_timestamp(((data ->> ('loppuPaiva')::varchar)::bigint / 1000)) at time zone 'utc'
            at time zone 'europe/helsinki'
        )::timestamptz) as loppupaiva,
        --to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as inserted, #Changed column name to muokattu
        --to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as muokattu,
        ((
            to_timestamp(((data ->> ('inserted')::varchar)::bigint / 1000)) at time zone 'utc'
            at time zone 'europe/helsinki'
        )::timestamptz) as muokattu,
        (data ->> 'deleted')::boolean as poistettu,
        data ->> 'source'::varchar as source,
        {{ metadata_columns() }}
    from source
)

select * from final
