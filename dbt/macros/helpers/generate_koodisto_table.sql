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

final as (
    select
    koodiuri || '#' || koodiversio::varchar as versioitu_koodiuri,
    koodiuri,
    {% if is_int -%}
    koodiarvo::int,
    {%- else -%}
    koodiarvo,
    {% endif -%}
    koodiversio,
    koodinimi_fi as nimi_fi,
    koodinimi_sv as nimi_sv,
    koodinimi_en as nimi_en,
    tila='LUONNOS' as viimeisin_versio
    from raw
)

select * from final
order by koodiversio,koodiarvo

{% endmacro -%}