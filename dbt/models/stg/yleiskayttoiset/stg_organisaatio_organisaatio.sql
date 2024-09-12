with source as (
    select * from {{ source('ovara', 'organisaatio_organisaatio') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}

),

final as (
    select
        data ->> 'organisaatio_oid' as organisaatio_oid,
        (data ->> 'alkupvm')::timestamptz as alkupvm,
        data ->> 'nimi_fi' as nimi_fi,
        data ->> 'nimi_sv' as nimi_sv,
        array_to_json(string_to_array((data ->> 'organisaatiotyypit')::varchar, ','))::jsonb as organisaatiotyypit,
        (data ->> 'paivityspvm')::timestamptz as muokattu,
        data ->> 'tila' as tila,
        data ->> 'grandparent_oid' as ylin_organisaatio,
        data ->> 'kotipaikka' as sijaintikunta,
        array_to_json(string_to_array((data ->> 'opetuskielet')::varchar, ','))::jsonb as opetuskielet,
        data ->> 'parent_oid' as ylempi_organisaatio,
        {{ metadata_columns() }}
    from source
)

select * from final
where organisaatiotyypit not in ('["organisaatiotyyppi_07"]'::jsonb, '["organisaatiotyyppi_08"]'::jsonb)
