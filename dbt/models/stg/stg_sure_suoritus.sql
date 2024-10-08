with source as (
    select * from {{ source('ovara', 'sure_suoritus') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

final as (
    select
        data ->> 'resourceId'::varchar as resourceid,
        data ->> 'komo'::varchar as komo,
        data ->> 'myontaja'::varchar as myontaja,
        data ->> 'tila'::varchar as tila,
        --data ->> 'valmistuminen'::varchar as valmistuminen,
        (data ->> 'valmistuminen')::timestamptz as valmistuminen,
        data ->> 'henkiloOid'::varchar as henkilooid,
        data ->> 'yksilollistaminen'::varchar as yksilollistaminen,
        data ->> 'suoritusKieli'::varchar as suorituskieli,
        --to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as inserted, #Changed column name to muokattu
        --to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as muokattu,
        ((
            to_timestamp(((data ->> ('inserted')::varchar)::bigint / 1000))
            at time zone 'utc' at time zone 'europe/helsinki'
        )::timestamptz) as muokattu,
        (data ->> 'deleted')::boolean as poistettu,
        data ->> 'source'::varchar as source,
        (data ->> 'vahvistettu')::boolean as vahvistettu,
        data -> 'lahdeArvot' ->> 'arvot'::varchar as arvot,
        {{ metadata_columns() }}

    from source

)

select * from final
