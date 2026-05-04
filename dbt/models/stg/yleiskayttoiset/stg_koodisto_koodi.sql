{{
  config(
    materialized = 'table',
    unlogged=true,
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
    ),

    int as (
        select
            data.koodiarvo,
            data.koodinimi_fi,
            data.koodinimi_sv,
            data.koodinimi_en,
            data.koodikuvaus_fi,
            data.koodikuvaus_sv,
            data.koodikuvaus_en,
            data.koodistouri,
            data.koodiuri,
            data.koodiversio,
            data.koodiversiocreated_at as luotu,
            data.koodiversioupdated_at as muokattu,
            data.tila,
            data.voimassaalkupvm,
            data.voimassaloppuvpm as voimassaloppupvm,
            {{ metadata_columns() }}
        from source
        cross join lateral json_to_record(data) as data (
            koodistouri text,
            koodiuri text,
            koodiarvo text,
            koodiversio int,
            tila text,
            voimassaalkupvm date,
            voimassaloppuvpm date,
            koodinimi_fi text,
            koodinimi_sv text,
            koodinimi_en text,
            koodikuvaus_fi text,
            koodikuvaus_sv text,
            koodikuvaus_en text,
            koodiversiocreated_at timestamp,
            koodiversioupdated_at timestamp
        )
    ),

    final as (
        select
            {{ dbt_utils.generate_surrogate_key(['koodistouri','koodiarvo','koodiversio']) }} as koodi_id,
            *
        from int
    )

    select * from final
{% endif %}
