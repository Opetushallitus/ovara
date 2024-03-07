{#
    Creates a list of column names from a given relation. A list of columns
    provides with the argument exclude_cols will be removed from the returned
    list.

    Typically this macro can be used to generate a list of hash columns for CDC.
    Meta columns are typically excluded from the hash.
#}
{% macro get_filtered_hash_column_list(source_model, exclude_cols) %}

{%- set columns = adapter.get_columns_in_relation(source_model) -%}

{%- set column_list = [] -%}

{%- if execute %}
    {%- for col in columns %}
        {% if not col.column.startswith(exclude_cols) %}
            {{ column_list.append('"' + col.column + '"') or '' }}
        {% endif %}
    {% endfor -%}

{% endif -%}

{{ return(column_list | sort) }}

{% endmacro %}
