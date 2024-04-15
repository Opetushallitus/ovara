{% macro muokattu_column() -%}
    (data ->> 'modified')::timestamptz as muokattu
{%- endmacro %}