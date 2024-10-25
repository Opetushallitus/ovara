{% macro tempdata_cleanup() -%}
{%- if target.name == 'prod' %}
    {% set query = 'select raw_table from raw.completed_dbt_runs where execute' %}
    {% set tables = run_query(query) %}
    {% set tables_list = tables.rows %}
    {% for row in tables_list %}
        {% set table = row[0] %}
        {% set sql = 'delete from raw.'+table+' where dw_metadata_dbt_copied_at < (select start_time from raw.completed_dbt_runs where raw_table = \''+table+'\')' %}
        {% do run_query(sql) %}
        --{{ print (sql) }}
        {% set sql = 'delete from stg.stg_'+table+' where dw_metadata_dbt_copied_at < (select start_time from raw.completed_dbt_runs where raw_table = \''+table+'\')' %}
        {% do run_query(sql) %}
    {% endfor %}
{% endif %}
{%- endmacro %}
