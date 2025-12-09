{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['koodi_id']},
        {'columns': ['muokattu']}
    ]

    )
}}

{% if is_loading('koodisto_koodi') %}
select * from {{ this }}
{% else %}

    with source as (
        select * from {{ source('ovara', 'koodisto_koodi') }}
{#
    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}

    #}
--    where
--        (data ->> 'updated')::timestamptz > (
--            select coalesce(max(muokattu), '1899-12-31') from {{ source('yleiskayttoiset', 'dw_koodisto_koodi') }}
--        )

    ),

    int as (
        select
            data ->> 'koodiarvo'::varchar as koodiarvo,
            data ->> 'koodinimi_fi'::varchar as koodinimi_fi,
            data ->> 'koodinimi_sv'::varchar as koodinimi_sv,
            data ->> 'koodinimi_en'::varchar as koodinimi_en,
            data ->> 'koodikuvaus_fi'::varchar as koodikuvaus_fi,
            data ->> 'koodikuvaus_sv'::varchar as koodikuvaus_sv,
            data ->> 'koodikuvaus_en'::varchar as koodikuvaus_en,
            data ->> 'koodistouri'::varchar as koodistouri,
            data ->> 'koodiuri'::varchar as koodiuri,
            (data ->> 'koodiversio')::int as koodiversio,
            (data ->> 'koodiversiocreated_at')::timestamptz as luotu,
            (data ->> 'koodiversioupdated_at')::timestamptz as muokattu,
            data ->> 'tila'::varchar as tila,
            (data ->> 'voimassaalkupvm')::timestamptz as voimassaalkupvm,
            (data ->> 'voimassaloppuvpm')::timestamptz as voimassaloppupvm,
            {{ metadata_columns() }}
        from source
    ),

    final as (
        select
            {{ dbt_utils.generate_surrogate_key(['koodistouri','koodiarvo','koodiversio']) }} as koodi_id,
            *
        from int
    )

    select * from final
{% endif %}
