{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'valinnanvaihe_id',
        indexes = [
            {'columns': ['valinnanvaihe_id']}
            ],
        incremental_predicates = [
            "DBT_INTERNAL_SOURCE.muokattu > DBT_INTERNAL_DEST.muokattu"
            ],
        enabled = false
)
}}

with source as (
    select distinct on (valinnanvaihe_id) *
    from {{ ref('stg_valintalaskenta_valintalaskennan_tulos') }}
    {% if is_incremental() -%}
        {# Only rows which are newer than the rows in dw model table already #}
        where (
            dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t),
                date('1900-01-01')
            )
            or dw_metadata_stg_stored_at is null
        )
    {%- endif %}
    order by valinnanvaihe_id asc, muokattu desc
)

select
    *,
    current_timestamp as dw_metadata_dw_stored_at
from source
