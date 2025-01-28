{% macro hakukohde_henkilo_id() %}
        {{ dbt_utils.generate_surrogate_key(
            ['hakukohde_oid',
            'henkilo_oid']
        ) }} as hakukohde_henkilo_id
{% endmacro %}