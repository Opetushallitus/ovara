{#
This macro uses a separate temp table for distinct values to be removed for tables where there are a lot of rows
to be deleted, and one unique id exist on many rows
#}

{% macro get_incremental_distinct_delete_insert_sql(arg_dict) %}

    {% do return(
        distinct_delete_insert_sql(
            arg_dict["target_relation"],
            arg_dict["temp_relation"],
            arg_dict["unique_key"],
            arg_dict["dest_columns"],
            arg_dict["incremental_predicates"]
        )
    ) %}

{% endmacro %}


{% macro distinct_delete_insert_sql(
    target_relation,
    temp_relation,
    unique_key,
    dest_columns,
    incremental_predicates
) %}

    {%- set dest_cols_csv =
        get_quoted_csv(dest_columns | map(attribute="name"))
    -%}

    {%- if unique_key is string -%}
        {%- set unique_keys = [unique_key] -%}
    {%- else -%}
        {%- set unique_keys = unique_key -%}
    {%- endif -%}

    {%- set key_table_name =
        adapter.quote(target_relation.identifier ~ "__dbt_delete_keys")
    -%}

    {% if unique_key %}

        drop table if exists {{ key_table_name }};

        create temporary table {{ key_table_name }}
        on commit drop
        as
        select distinct
            {% for key in unique_keys %}
                {{ adapter.quote(key) }}
                {%- if not loop.last %},{% endif %}
            {% endfor %}
        from {{ temp_relation }};

        analyze {{ key_table_name }};

        delete from {{ target_relation }}
            as dbt_internal_dest
        using {{ key_table_name }}
            as dbt_internal_source
        where
            {% for key in unique_keys %}
                dbt_internal_dest.{{ adapter.quote(key) }}
                    = dbt_internal_source.{{ adapter.quote(key) }}
                {%- if not loop.last %}
                    and
                {% endif %}
            {% endfor %}

            {% if incremental_predicates %}
                {% for predicate in incremental_predicates %}
                    and {{ predicate }}
                {% endfor %}
            {% endif %};

    {% endif %}

    insert into {{ target_relation }} (
        {{ dest_cols_csv }}
    )
    select
        {{ dest_cols_csv }}
    from {{ temp_relation }};

{% endmacro %}