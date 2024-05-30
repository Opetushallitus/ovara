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

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

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
