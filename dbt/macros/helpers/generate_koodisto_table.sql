{%- macro generate_koodisto_table(koodistouri,is_int=false) -%}

{# is_int is a boolean field.
It defines wether the code value in the table is an integer or not.
The default is false meaning the column is created as textS
#}

{{
  config(
    indexes=[
        {'columns':['koodiarvo','viimeisin_versio']},
        {'columns':['koodiarvo','koodiversio']},
    ]
    )
}}

with raw as
(
    select *
    from {{ ref('dw_koodisto_koodi') }}
    where koodistouri='{{koodistouri}}'
),

int as (
    select
        koodiuri || '#' || koodiversio::varchar as versioitu_koodiuri,
        koodiuri,
        {% if is_int -%}
        koodiarvo::int,
        {%- else -%}
        koodiarvo,
        {% endif -%}
        koodiversio,
        coalesce(koodinimi_fi,koodinimi_sv,koodinimi_en) as nimi_fi,
        coalesce(koodinimi_sv,koodinimi_fi,koodinimi_en) as nimi_sv,
        coalesce(koodinimi_en,koodinimi_fi,koodinimi_sv) as nimi_en,
        tila='LUONNOS' as viimeisin_versio,
        voimassaalkupvm,
        voimassaloppupvm
    from raw
),

final as (
    select
        *,
            jsonb_build_object(
            'fi',nimi_fi,
            'sv',nimi_sv,
            'en',nimi_en
        )::jsonb as koodinimi
    from int
)

select * from final
order by koodiarvo,koodiversio

{% endmacro -%}