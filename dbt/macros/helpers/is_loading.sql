{% macro is_loading(file) -%}
{% if execute %}
    {% set query %}
        select exists (select * from raw.loading where file='{{ file }}')
    {% endset %}

    {% set result = run_query(query) %}
    {% set loading = result.columns[0][0] | as_bool %}
    {{ return(loading) }}

{% endif %}
{% endmacro%}
