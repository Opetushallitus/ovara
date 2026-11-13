{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['toteutus_oid']}
    ]
    )
}}

with tiedot as (
	select
		toteutus_oid,
		jsonb_array_elements(lisatiedot) as lisatieto
	from {{ ref('int_kouta_toteutus') }}
),

tyypit as (
	select
		versioitu_koodiuri,
		koodiarvo,
		nimi_fi,
		nimi_sv,
		nimi_en
	from {{ ref('int_koodisto_koulutuksenlisatiedot') }}
),

final as (
    select
        tiedot.toteutus_oid,
        tiedot.lisatieto -> 'teksti' ->> 'fi' as koulutuksen_lisatieto_fi,
        tiedot.lisatieto -> 'teksti' ->> 'sv' as koulutuksen_lisatieto_sv,
        tiedot.lisatieto -> 'teksti' ->> 'en' as koulutuksen_lisatieto_en,
        tyypit.koodiarvo as lisatietotyyppi,
        tyypit.nimi_fi as lisatietotyyppi_nimi_fi,
        tyypit.nimi_sv as lisatietotyyppi_nimi_sv,
        tyypit.nimi_en as lisatietotyyppi_nimi_en
    from tiedot
    join tyypit on tiedot.lisatieto ->> 'otsikkoKoodiUri' = tyypit.versioitu_koodiuri
)

select * from final