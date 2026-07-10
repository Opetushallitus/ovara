{#
Overwrite default delete from where logic for delete insert with delete using.
MR/10.7.2026
#}
{% macro postgres__get_incremental_delete_insert_sql(arg_dict) %}

    {% set target = arg_dict["target_relation"] %}
    {% set source = arg_dict["temp_relation"] %}
    {% set unique_key = arg_dict["unique_key"] %}
    {% set dest_columns = arg_dict["dest_columns"] %}
    {% set incremental_predicates = arg_dict["incremental_predicates"] %}
    {% set dest_cols_csv = get_quoted_csv(
        dest_columns | map(attribute="name")
    ) %}

    {% if unique_key is string %}
        {% set unique_keys = [unique_key] %}
    {% else %}
        {% set unique_keys = unique_key %}
    {% endif %}

    {% set sql %}

        {% if unique_keys %}

        delete from {{ target }} as DBT_INTERNAL_DEST
        using (
            select distinct
            {% for key in unique_keys -%}
                {{ key }}{% if not loop.last %},{% endif -%}
            {% endfor %}
            from {{ source }}
    ) as DBT_INTERNAL_SOURCE
            where
                {%- for key in unique_keys %}
                    DBT_INTERNAL_DEST.{{ key }} = DBT_INTERNAL_SOURCE.{{ key }}
                    {% if not loop.last %}
                        and
                    {%- endif %}
                {%- endfor %}

                {%- if incremental_predicates %}
                    {%- for predicate in incremental_predicates %}
                        and ({{ predicate }})
                    {% endfor -%}
                {% endif %}
            ;

        {% endif %}

        insert into {{ target }} (
            {{ dest_cols_csv }}
        )
        select
            {{ dest_cols_csv }}
        from {{ source }}
        ;

    {% endset %}

    {% do return(sql) %}

{% endmacro %}