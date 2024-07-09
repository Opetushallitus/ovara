{% macro generate_dw_model_muokattu(src_model,key_columns_list) %}
{#
    src_model needs to be provided as ref(), key_columns_list as an array
#}

{{-
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        full_refresh = false,
        on_schema_change = 'append_new_columns',
        unique_key = key_columns_list,
        merge_exclude_columns = [
            'dw_metadata_dbt_copied_at',
            'dw_metadata_file_row_number',
            'dw_metadata_filename',
            'dw_metadata_source_timestamp_at',
            'dw_metadata_stg_stored_at',
            'dw_metadata_dw_stored_at'
            ],
        indexes = [
            {'columns': key_columns_list},
            {'columns': ['dw_metadata_dw_stored_at']}
        ]
    )
-}}

with _raw as (
    select
    *,
    row_number() over (partition by
    {% for column in key_columns_list -%}
        {{column}}
        {%- if not loop.last -%}
        ,
        {%- endif -%}
    {%- endfor %}
    order by dw_metadata_dbt_copied_at desc) as rownr
    from
    {{ src_model }}
    {% if is_incremental() -%}
    {# Only rows which are newer than the rows in dw model table already #}
    where (dw_metadata_stg_stored_at > coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}),date('1900-01-01'))
            or dw_metadata_stg_stored_at is null)
    {%- endif %}

),
date as (
    select *,
    current_timestamp as dw_metadata_dw_stored_at
    from _raw where rownr=1
),

final as (
    select
        {{ dbt_utils.star(from=src_model) }},
        dw_metadata_dw_stored_at
    from date
)

select * from final
{% endmacro %}