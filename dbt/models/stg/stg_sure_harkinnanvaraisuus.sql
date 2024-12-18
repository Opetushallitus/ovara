with source as (
    select * from {{ source('ovara', 'sure_harkinnanvaraisuus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'hakemusOid' as hakemusOid,
        (data -> 'hakutoiveet')::jsonb as hakutoiveet,
        {{ metadata_columns() }}
    from source
)

select * from final
