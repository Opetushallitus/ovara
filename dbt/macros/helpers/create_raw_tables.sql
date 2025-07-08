{% macro create_raw_tables() -%}

{% set query %}
    SELECT raw_taulu from {{ ref('raw_taulut') }}
{% endset %}

{% set tables = run_query(query) %}

{%set tables_list = tables.columns[0].values()  %}

{% if execute %}
    {% for table in tables_list %}
        {% set create_statement = 'create table if not exists raw.' + table +' (
	"data" json NULL,
	dw_metadata_source_timestamp_at timestamptz NULL,
	dw_metadata_dbt_copied_at timestamptz NULL,
	dw_metadata_filename varchar NULL,
	dw_metadata_file_row_number int4 NULL
    );
    CREATE INDEX if not exists ix_'+ table + ' ON raw.' + table+ ' USING btree (dw_metadata_dbt_copied_at);
    ALTER TABLE raw.' + table+ ' set (autovacuum_enabled=off);'
%}
        {{ print ( create_statement )}}
        {% do run_query(create_statement) %}
        {% endfor %}

{% endif %}
{%- endmacro %}