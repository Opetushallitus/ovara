with source as (
    select * from {{ source('ovara', 'valintaperusteet_avain') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'hakukohdeOid' as hakukohde_oid,
        current_timestamp as muokattu,
        data,
        {{ metadata_columns() }}
    from source
)

select * from final
