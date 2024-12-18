with source as (
    select * from {{ source('ovara', 'hakukohderyhmapalvelu_ryhma') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'hakukohderyhma-oid' as oid,
        (data -> 'hakukohde-oids')::jsonb as hakukohde_oid,
        (data -> 'settings' ->> 'rajaava')::boolean as rajaava,
        (data -> 'settings' ->> 'max-hakukohteet')::int as max_hakukohteet,
        (data -> 'settings' ->> 'yo-amm-autom-hakukelpoisuus')::boolean as yo_amm_autom_hakukelpoisuus,
        (data -> 'settings' ->> 'jos-ylioppilastutkinto-ei-muita-pohjakoulutusliitepyyntoja')::boolean
        as jos_ylioppilastutkinto_ei_muita_pohjakoulutusliitepyyntoja,
        (data -> 'settings' ->> 'priorisoiva')::boolean as priorisoiva,
        (data -> 'settings' -> 'prioriteettijarjestys')::jsonb as prioriteettijarjestys,
        (data ->> 'last-modified')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
