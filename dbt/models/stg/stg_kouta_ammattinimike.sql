with source as (
    select * from {{ source('ovara', 'kouta_ammattinimike') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

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
