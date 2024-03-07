{#
    Ignore the target schema in production environments and ignore the custom schema configurations in other environments ie. test.
    https://docs.getdbt.com/docs/build/custom-schemas#a-built-in-alternative-pattern-for-generating-schema-names
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ generate_schema_name_for_env(custom_schema_name, node) }}
{%- endmacro %}
