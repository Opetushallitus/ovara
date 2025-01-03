with source as (
    select * from {{ source('ovara', 'kouta_ammattinimike') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'kieli' as kieli,
        data ->> 'arvo' as arvo,
        {{ metadata_columns() }}
    from source
)

select * from final
