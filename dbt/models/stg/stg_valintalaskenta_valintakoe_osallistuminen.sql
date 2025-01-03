{{
  config(
    indexes=[
        {'columns':['hakemusOid','muokattu'] }
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'valintalaskenta_valintakoe_osallistuminen') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'hakemusOid'::varchar as hakemusOid,
        (data -> 'hakutoiveet')::jsonb as hakutoiveet,
        (data ->> 'createdAt')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
