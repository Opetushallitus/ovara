{% macro stg_start() -%}
{%- if target.name == 'prod' %}

{% set query = 'CREATE TABLE if not exists raw.dbt_runs (model text NULL,start_time timestamptz NULL);'%}
{% do run_query(query) %}

    with data as (
	select
		'{{ this }}' as model,
		case
			when environment = 'test' then date_trunc('day',current_timestamp+interval '2 days')
			else current_timestamp
			end as start_time
	from raw.environment
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