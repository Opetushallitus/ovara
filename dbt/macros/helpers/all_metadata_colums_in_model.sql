{% macro all_metadata_columns_in_model(stage_model) -%}

{%- set columns = adapter.get_columns_in_relation(stage_model) -%}

{%- set column_list = [] -%}

{%- if execute %}
    {%- for col in columns %}
        {% if col.column.startswith('dw_metadata_') %}
            {{ column_list.append(col.column) or '' }}
        {% endif %}
    {% endfor -%}

{% endif -%}

{{ return(column_list | sort) }}

{% endmacro %}
