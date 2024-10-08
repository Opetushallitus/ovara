{%- macro generate_koodisto_pub_view(int_model,type='view') -%}

{#
    default is view, but the value 'table' can be used when calling the macro to create a table instead of a view
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
