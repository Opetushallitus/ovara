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

with source as
(
    select
    *,
    tila='LUONNOS' as viimeisin_versio
    from {{ ref('int_koodisto_koodi') }}
    where koodistouri='{{koodistouri}}'
)


select
    versioitu_koodiuri,
    koodiuri,
    {% if is_int -%}
    koodiarvo::int,
    {%- else -%}
    koodiarvo,
    {% endif -%}
    koodiversio,
    koodinimi,
    nimi_fi,
    nimi_sv,
    nimi_en,
    viimeisin_versio,
    voimassaalkupvm,
    voimassaloppupvm
from source
order by koodiarvo,koodiversio

{% endmacro -%}