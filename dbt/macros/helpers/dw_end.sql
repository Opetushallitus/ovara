{% macro dw_end() -%}
{%- if target.name == 'prod' %}

{% set query = 'CREATE TABLE if not exists raw.completed_dbt_runs (model text NULL, raw_table text NULL, start_time timestamptz NULL,	"execute" bool NULL);' %}
{% do run_query(query) %}

with raw as (
    select
        model,
        replace(regexp_replace(split_part(model, '.', 3),'stg_',''),'"','') as raw_table,
        start_time
        from raw.dbt_runs dr
    where model = replace ('{{ this }}','dw','stg')
),

data as (
    select
        model,
        raw_table,
        case when raw_table = 'onr_henkilo' then start_time - interval '1 hour' else start_time end as start_time
    from raw
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