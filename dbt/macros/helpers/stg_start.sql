{% macro stg_start() -%}
{%- if target.name == 'prod' %}
    with data as (
	select
		'{{ this }}' as model,
		current_timestamp as start_time
)

merge into raw.dbt_runs as t
using data as s
	on t.model = s.model
when matched
	then update set start_time=s.start_time
when not matched
then insert values (model,start_time)
{% endif %}
{%- endmacro %}