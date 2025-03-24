{% macro generate_dw_model_muokattu(src_model,key_columns_list) %}
{#
    src_model needs to be provided as ref(), key_columns_list as an array

    add the bolw line to config to prevent accidental removal of history rows from dw tables

          full_refresh = false,
#}

{{-
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        on_schema_change = 'append_new_columns',
        unique_key = key_columns_list,
        merge_exclude_columns = [
            'dw_metadata_dbt_copied_at',
            'dw_metadata_file_row_number',
            'dw_metadata_filename',
            'dw_metadata_source_timestamp_at',
            'dw_metadata_dw_stored_at'
            ],
        indexes = [
            {'columns': key_columns_list},
            {'columns': ['dw_metadata_stg_stored_at']}
        ]
    )
-}}

with _raw as (
    select distinct on (
    {% for column in key_columns_list -%}
        {{column}}
        {%- if not loop.last -%}
        ,
        {%- endif -%}
    {%- endfor %}
    )
    *
    from
    {{ src_model }}
    {% if is_incremental() -%}
    {# Only rows which are newer than the rows in dw model table already #}
    where (dw_metadata_stg_stored_at > coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}),date('1900-01-01'))
            or dw_metadata_stg_stored_at is null)
    {%- endif %}
    order by {% for column in key_columns_list -%}
        {{column}}
    ,
    {%- endfor %}
    dw_metadata_dbt_copied_at desc
),

final as (
    select
        {{ dbt_utils.star(from=src_model) }},
            current_timestamp as dw_metadata_dw_stored_at
    from _raw
)

select * from final
{% endmacro %}