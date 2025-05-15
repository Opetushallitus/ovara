{%- macro generate_koodisto_pub_view(int_model,type='table') -%}

{#
    default is table, but the value 'view' can be used when calling the macro to create a view instead of a table
#}


{% if type=='table' %}
	{{
		config (
			materialized='table',
			indexes = [{'columns':['koodiarvo']}]
		)
	}}
{% else %}
	{{
			config (
			materialized='view'
		)
	}}
{% endif %}

select
	{{ dbt_utils.star(from=int_model, except=['viimeisin_versio'] ) }}
from {{ int_model }}
where viimeisin_versio

{% endmacro -%}
