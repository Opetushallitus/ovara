with source as (
      select * from {{ source('ovara', 'sure_opiskeluoikeus') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(   
    select 
        data ->> 'resourceId'::varchar as resourceid,
        to_timestamp((data ->> ('alkuPaiva')::varchar)::bigint /1000 ) as alkupaiva,
        to_timestamp((data ->> ('loppuPaiva')::varchar)::bigint /1000 ) as loppupaiva,
        data ->> 'henkiloOid'::varchar as henkilooid,
        data ->> 'komo'::varchar as komo,
        data ->> 'myontaja'::varchar as myontaja,
        data ->> 'source'::varchar as source,
        --to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as inserted, #Changed column name to muokattu
        to_timestamp((data ->> ('inserted')::varchar)::bigint /1000 ) as muokattu,
        (data ->> 'deleted')::boolean as deleted,
        {{ metadata_columns() }}

        from source

)

select * from final