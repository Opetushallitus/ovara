with source as (
    select * from {{ source('ovara', 'ohjausparametrit_parameter') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

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
