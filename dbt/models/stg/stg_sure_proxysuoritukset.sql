with source as (
    select * from {{ source('ovara', 'sure_proxysuoritukset') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
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
