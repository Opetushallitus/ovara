with source as (
    select * from {{ source('ovara', 'valintarekisteri_yhdenopiskeluoikeudensaados') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'hakemusOid' as hakemus_oid,
        data ->> 'hakukohdeOid' as hakukohde_oid,
        (data ->> 'systemTime')::timestamptz as muokattu,
        data,
        {{ metadata_columns() }}
    from source
)

select
    {{ hakutoive_id() }},
    *
from final

