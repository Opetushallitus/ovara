with source as (
    select * from {{ source('ovara', 'ataru_lomake') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )
    {% endif %}
),

int as (
    select
        (data ->> 'key')::uuid as id,
        (data ->> 'id')::int as versio_id,
        data ->> 'deleted'::varchar as poistettu,
        data -> 'name' ->> 'fi'::varchar as nimi_fi,
        data -> 'name' ->> 'sv'::varchar as nimi_sv,
        data -> 'name' ->> 'en'::varchar as nimi_en,
        (data -> 'languages')::jsonb as kielivalinta,
        data ->> 'organization-oid'::varchar as organisaatio_oid,
        (data ->> 'created-time')::timestamptz as muokattu,
        data ->> 'created-by'::varchar as luoja,
        (data -> 'flat-content')::jsonb as content, --noqa: RF04,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['id', 'versio_id']) }} as lomake_id_versioid_id,
        *,
            content @> '[{"id": "1dc3311d-2235-40d6-88d2-de2bd63e087b"}]'
	        or content @> '[{"id": "ammatillinen_perustutkinto_urheilijana"}]'
	        or content @> '[{"id": "4fe08958-c0b7-4847-8826-e42503caa662"}]'
	        or content @> '[{"id": "32b8440f-d6f0-4a8b-8f67-873344cc3488"}]'
	        or content @> '[{"id": "lukio_opinnot_ammatillisen_perustutkinnon_ohella"}]'
	        or content @> '[{"id": "ammatilliset_opinnot_lukio_opintojen_ohella"}]'
		as kaksois_urheilija_tutkinto
    from (
        select
        (data ->> 'key')::uuid as id,
        (data ->> 'id')::int as versio_id,
        data ->> 'deleted'::varchar as poistettu,
        data -> 'name' ->> 'fi'::varchar as nimi_fi,
        data -> 'name' ->> 'sv'::varchar as nimi_sv,
        data -> 'name' ->> 'en'::varchar as nimi_en,
        (data -> 'languages')::jsonb as kielivalinta,
        data ->> 'organization-oid'::varchar as organisaatio_oid,
        (data ->> 'created-time')::timestamptz as muokattu,
        data ->> 'created-by'::varchar as luoja,
        (data -> 'flat-content')::jsonb as content, --noqa: RF04,
        {{ metadata_columns() }}
    from source) as raw

)

select * from final
