{% macro disable_autovacuum_if_not_incremental() %}
    {% if model.config.materialized == 'table' %}
        alter table {{ this }} set (autovacuum_enabled = false)
    {% else %}
        select 1
    {% endif %}
{% endmacro %}