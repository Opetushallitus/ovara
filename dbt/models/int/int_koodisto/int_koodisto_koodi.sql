{{
  config(
    indexes=[
        {'columns':['koodiarvo','viimeisin_versio']},
        {'columns':['koodiarvo','koodiversio']},
        {'columns': ['koodistouri']}
    ]
    )
}}

with raw as (
    select *
    from {{ ref('dw_koodisto_koodi') }}
),

int as (
    select
        koodistouri,
        koodiuri || '#' || koodiversio::varchar as versioitu_koodiuri,
        koodiuri,
        {% if is_int -%}
        koodiarvo::int,
            {%- else -%}
            koodiarvo,
        {% endif -%}
        koodiversio,
        coalesce(koodinimi_fi, coalesce(koodinimi_sv, koodinimi_en)) as nimi_fi,
        coalesce(koodinimi_sv, coalesce(koodinimi_fi, koodinimi_en)) as nimi_sv,
        coalesce(koodinimi_en, coalesce(koodinimi_fi, koodinimi_sv)) as nimi_en,
        tila = 'LUONNOS' as viimeisin_versio
    from raw
),

final as (
    select
        *,
        jsonb_build_object(
            'fi', nimi_fi,
            'sv', nimi_sv,
            'en', nimi_en
        )::jsonb as koodinimi
    from int
)

select * from final
order by koodiarvo, koodiversio
