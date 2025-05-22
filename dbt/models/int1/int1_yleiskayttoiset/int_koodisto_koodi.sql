{{
  config(
    indexes=[
        {'columns':['koodiarvo','koodiversio']},
        {'columns': ['koodistouri']}
    ]
    )
}}

with raw as (
    select *
    from {{ ref('dw_koodisto_koodi') }}
),

final as (
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
        jsonb_build_object(
            'fi', coalesce(koodinimi_fi, koodinimi_sv, koodinimi_en),
            'sv', coalesce(koodinimi_sv, koodinimi_fi, koodinimi_en),
            'en', coalesce(koodinimi_en, koodinimi_fi, koodinimi_sv)
        )::jsonb as koodinimi,
        koodinimi_fi as nimi_fi,
        koodinimi_sv as nimi_sv,
        koodinimi_en as nimi_en,
        tila,
        voimassaalkupvm,
        voimassaloppupvm
    from raw
)

select * from final
order by koodiarvo, koodiversio
