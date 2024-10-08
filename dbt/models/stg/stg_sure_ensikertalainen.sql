with source as (
    select * from {{ source('ovara', 'sure_ensikertalainen') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

final as (
    select
        data ->> 'hakuOid'::varchar as hakuoid,
        data ->> 'henkiloOid'::varchar as henkilooid,
        (data ->> 'isEnsikertalainen')::boolean as isensikertalainen,
        data -> 'menettamisenPeruste' ->> 'peruste'::varchar as menettamisenperuste,
        (data -> 'menettamisenPeruste' ->> 'paivamaara')::timestamptz as menettamisenpaivamaara,
        {{ metadata_columns() }}

    from source
)

select * from final
