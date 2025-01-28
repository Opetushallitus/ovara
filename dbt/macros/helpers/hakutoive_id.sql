{% macro hakutoive_id() %}
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'hakukohde_oid']
        ) }} as hakutoive_id
{% endmacro %}