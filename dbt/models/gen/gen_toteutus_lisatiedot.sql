{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['toteutus_oid']}
        ]
    )
}}

with lisatiedot as (
	select
		toteutus_oid,
		jsonb_array_elements(lisatiedot) as lisatieto
    from {{ ref('int_kouta_toteutus') }}
    where lisatiedot != '[]'::jsonb
),

koodisto as (
    select
        versioitu_koodiuri,
        koodiarvo,
        koodinimi
    from {{ ref('int_koodisto_koulutuksenlisatiedot') }}
),

final as (
    select
        liti.toteutus_oid,
        kood.koodiarvo as lisatieto_tyyppi,
        liti.lisatieto -> 'teksti' ->> 'fi' as teksti_fi,
        liti.lisatieto -> 'teksti' ->> 'sv' as teksti_sv,
        liti.lisatieto -> 'teksti' ->> 'en' as teksti_en,
        kood.koodinimi ->> 'fi' as lisatieto_nimi_fi,
        kood.koodinimi ->> 'sv' as lisatieto_nimi_sv,
        kood.koodinimi ->> 'en' as lisatieto_nimi_en
    from lisatiedot as liti
    join koodisto kood on liti.lisatieto ->> 'otsikkoKoodiUri' = kood.versioitu_koodiuri
)

select * from final
