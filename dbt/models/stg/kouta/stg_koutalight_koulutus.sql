with source as (
    select * from {{ source('ovara', 'koutalight_koulutus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
)

select
    (data ->> 'id')::uuid as koulutus_id,
    (data ->> 'updatedAt')::timestamptz as muokattu,
    data,
    {{ metadata_columns() }}
from source
