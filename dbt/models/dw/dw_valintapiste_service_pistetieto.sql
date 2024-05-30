{{
  config(
    indexes = [{'columns':['hakemus_oid']}],
    materialized = 'incremental',
    incremental_strategy = 'append',
    full_refresh = false,
    on_schema_change = 'append_new_columns'
    )
}}

with _raw as (
    select
        *,
        row_number() over (partition by hakemus_oid order by dw_metadata_dbt_copied_at desc) as rownr
    from {{ ref('stg_valintapiste_service_pistetieto') }}
    {% if is_incremental() -%}
        {# Only rows which are newer than the rows in dw model table already #}
        where (
            dw_metadata_dbt_copied_at >= coalesce(
                (select max(dw_metadata_dw_stored_at) from {{ this }}), date('1900-01-01')
            )
            or dw_metadata_dbt_copied_at is null
        )
    {%- endif %}

),

_final as (
    select
        *,
        md5(cast(pisteet as varchar)) as dw_metadata_hash,
        md5(cast(hakemus_oid as varchar)) as dw_metadata_key,
        coalesce(dw_metadata_source_timestamp_at, dw_metadata_dbt_copied_at) as dw_metadata_timestamp,
        current_timestamp as dw_metadata_dw_stored_at
    from _raw
    where
        rownr = 1
        {% if is_incremental() -%}
            and
            {# and only rows which has different hash #}
            md5(cast(hakemus_oid as varchar)) not in (select distinct
                last_value(dw_metadata_hash)
                    over
                    (
                        partition by dw_metadata_key
                        order by dw_metadata_timestamp asc
                    )
                as latest_hash
            from {{ this }})
        {%- endif %}
)

select
    hakemus_oid,
    pisteet,
    {{ metadata_columns() }},
    dw_metadata_hash,
    dw_metadata_key,
    dw_metadata_timestamp,
    dw_metadata_dw_stored_at
from _final
