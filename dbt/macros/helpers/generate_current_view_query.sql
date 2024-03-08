{#
    Generates a query for a current view based on a dw table.
    That is, will fetch the latest record per each source primary key.
#}
{% macro generate_current_view_query(model_name) %}

{%- set dw_relation_name = model_name -%}
{%- set key_column_name = 'dw_metadata_key' -%}
{%- set hash_column_name = 'dw_metadata_hash' -%}
{%- set data_timestamp_name = 'dw_metadata_timestamp' -%}
{%- set dw_stored_at_name = 'dw_metadata_dw_stored_at' -%}

{%- set query_string %}
with _latest_hash_per_key as (
    -- one row per key, content has, source timestamp and dw stored time
    select  
        *,
        row_number() over(
        partition by
            {{ key_column_name }}
        order by
            {{ data_timestamp_name }} desc,
            {{ dw_stored_at_name }} desc
        ) as _row_order
    from {{ ref(dw_relation_name) }}
)

select 

{%- set column_names = dbt_utils.get_filtered_columns_in_relation(from=this, except=['_row_order']) %}
{% for column_name in column_names -%}
   {{ column_name }}
   {%- if not loop.last %}
    ,
    {%- endif -%}
{% endfor -%}



from _latest_hash_per_key
where _row_order = 1

{%- endset %}

{{ return(query_string) }}

{% endmacro -%}
