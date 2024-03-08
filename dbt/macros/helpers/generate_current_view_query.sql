{#
    Generates a query for a current view based on a dw table.
    That is, will fetch the latest record per each source primary key.
#}
{% macro generate_current_view_query(model_name) %}

{%- set dw_relation_name = model_name -%}
{%- set key_column_name = 'dw_metadata_' + model_name + '_key' -%}
{%- set hash_column_name = 'dw_metadata_' + model_name + '_hash' -%}
{%- set data_timestamp_name = 'dw_metadata_' + model_name + '_timestamp' -%}
{%- set dw_stored_at_name = 'dw_metadata_' + model_name + '_dw_stored_at' -%}

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
    qualify _row_order = 1
)

select * exclude _row_order
from _latest_hash_per_key

{% endset %}

{{ return(query_string) }}

{% endmacro %}
