with source as (
    select * from {{ source('ovara', 'ataru_lomake') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )
    {% endif %}
),

final as (
    select
        (data ->> 'key')::uuid as id,
        (data ->> 'id')::int as versio_id,
        data ->> 'deleted'::varchar as poistettu,
        data -> 'name' ->> 'fi'::varchar as nimi_fi,
        data -> 'name' ->> 'sv'::varchar as nimi_sv,
        data -> 'name' ->> 'en'::varchar as nimi_en,
        (data -> 'languages')::jsonb as kielivalinta,
        data ->> 'organization-oid'::varchar as organisaatio_oid,
        (data ->> 'created-time')::timestamptz as muokattu,
        data ->> 'created-by'::varchar as luoja,
        (data -> 'flat-content')::jsonb as content, --noqa: RF04
        {{ metadata_columns() }}
    from source
)

select * from final
