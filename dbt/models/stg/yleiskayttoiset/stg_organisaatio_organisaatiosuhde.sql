with source as (
    select * from {{ source('ovara', 'organisaatio_organisaatiosuhde') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

int as (
    select
        data ->> 'suhdetyyppi' as suhdetyyppi,
        data ->> 'parent_oid' as parent_oid,
        data ->> 'child_oid' as child_oid,
        (data ->> 'alkupvm')::timestamptz as alkupvm,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
				'suhdetyyppi',
				'parent_oid',
                'child_oid'
			]) }} as suhde_id,
        *
    from int
)

select * from final
