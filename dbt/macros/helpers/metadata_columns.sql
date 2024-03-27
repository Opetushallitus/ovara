{% macro metadata_columns() %}
    dw_metadata_source_timestamp_at,
    dw_metadata_dbt_copied_at,
    dw_metadata_filename,
    dw_metadata_file_row_number
{% endmacro %}