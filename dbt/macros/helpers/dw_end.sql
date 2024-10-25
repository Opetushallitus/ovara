{% macro dw_end() -%}
{%- if target.name == 'prod' %}
with data as (
    select
        model,
        replace(regexp_replace(split_part(model, '.', 3),'stg_',''),'"','') as raw_table,
        start_time
        from raw.dbt_runs dr
    where model = replace ('{{ this }}','dw','stg')
)

merge into raw.completed_dbt_runs as t
using data as s
	on t.model = s.model
when matched
	then update set start_time=s.start_time
when not matched
then insert values (model,raw_table,start_time,false)
{% endif %}
{%- endmacro %}