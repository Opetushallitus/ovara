with source as (
    select * from {{ source('ovara', 'valintaperusteet_hakukohde') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'hakukohdeOid'::varchar as hakukohde_oid,
        data ->> 'hakuOid'::varchar as haku_oid,
        (data ->> 'lastModified')::timestamptz as muokattu,
        data ->> 'tarjoajaOid'::varchar as tarjoaja_oid,
        (data -> 'hakukohteenValintaperuste')::jsonb as hakukohteenValintaperuste,
        (data -> 'valinnanVaiheet')::jsonb as valinnanvaiheet,
        {{ metadata_columns() }}
    from source
)

select * from final
