with source as (
    select * from {{ source('ovara', 'ohjausparametrit_parameter') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'key' as id,
        (data ->> 'lastModified')::timestamptz as muokattu,
        (data -> 'values')::jsonb as arvot,
        {{ metadata_columns() }}
    from source
)

select * from final
