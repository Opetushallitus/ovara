{#
    Generates a query for incremental dw table.
    DW_METADATA columns are filtered out when calculation row hash
#}
{%- macro generate_dw_model(stage_model, key_columns_list) -%}

{%- set base_model_name = "" %}
{%- set stage_model_name = stage_model.identifier | string -%}

{%- if stage_model_name.startswith("stg_") %}
    {%- set base_model_name = stage_model_name.replace("stg_", "") -%}
{% else %}
    {%- set base_model_name = stage_model_name-%}
{% endif -%}

{%- set columns_to_hash = get_filtered_hash_column_list(stage_model, 'DW_METADATA_') -%}

{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append',
        full_refresh = false,
        on_schema_change = 'append_new_columns'
    )
}}

with 

_raw as (
    select 
    *,
    row_number() over (partition by oid, muokattu order by dw_metadata_dbt_copied_at desc) as rownr
    from 
    {{ stage_model }}
),
_final as (
    select *,
    {{ dbt_utils.generate_surrogate_key(columns_to_hash) }} as dw_metadata_hash,
    {{ dbt_utils.generate_surrogate_key(key_columns_list) }} as dw_metadata_key,
    coalesce(dw_metadata_source_timestamp_at, dw_metadata_dbt_copied_at) as dw_metadata_timestamp,
    current_timestamp as dw_metadata_dw_stored_at
    from _raw where rownr=1
    {% if is_incremental() -%}
    and
        {# Only rows which are newer than the rows in dw model table already #}
        (dw_metadata_dbt_copied_at >= coalesce((select max(dw_metadata_dbt_copied_at) from {{ this }}),date('1900-01-01'))
            or dw_metadata_dbt_copied_at is null) and
        {# and only rows which has different hash #}
        {{ dbt_utils.generate_surrogate_key(columns_to_hash) }} not in (select distinct last_value(dw_metadata_hash) over
            (partition by dw_metadata_key
            order by dw_metadata_timestamp asc) as latest_hash
            from {{ this }})
    {%- endif %}
)

select * from _final

{% endmacro -%}
