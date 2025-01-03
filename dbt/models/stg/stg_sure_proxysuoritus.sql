with source as (
    select * from {{ source('ovara', 'sure_proxysuoritus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'hakemusOid' as hakemusOid,
        data ->> 'hakuOid' as hakuOid,
        data ->> 'henkiloOid' as HenkiloOid,
        (data -> 'values' ->> 'POHJAKOULUTUS')::text as pohjakoulutus,
        (data -> 'values')::jsonb as keyvalues,
        {{ metadata_columns() }}
    from source
)

select * from final
