{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['koulutus_oid']}
    ]
    )
}}

with koulutus as (
    select * from {{ ref('int_kouta_koulutus') }}
),

final as (
    select
        koulutus_oid,
        koulutus_nimi ->> 'fi' as koulutus_nimi_fi,
        koulutus_nimi ->> 'sv' as koulutus_nimi_sv,
        koulutus_nimi ->> 'en' as koulutus_nimi_en,
        organisaatio_oid,
        externalid as ulkoinen_tunniste,
        johtaatutkintoon as johtaa_tutkintoon,
        koulutustyyppi,
        koulutuksetkoodiuri as koulutukset_koodiuri,
        tila,
        esikatselu,
        tarjoajat,
        julkinen,
        kielivalinta,
        sorakuvausid,
        tyyppi,
        kuvaus ->> 'fi' as koulutus_kuvaus_fi,
        kuvaus ->> 'sv' as koulutus_kuvaus_sv,
        kuvaus ->> 'en' as koulutus_kuvaus_en,
        lisatiedot,
        tutkinnonosat,
        koulutusalakoodiurit as koulutusala_koodiurit,
        tutkintonimikekoodiurit as tutkintonimike_koodiurit,
        opintojenlaajuusyksikkokoodiuri as opintojen_laajuus_yksikko_koodiuri,
        opintojenlaajuusnumero as opintojen_laajuus_numero,
        opintojenlaajuusnumeromin as opintojen_laajuus_numero_min,
        opintojenlaajuusnumeromax as opintojen_laajuus_numero_max,
        isavoinkorkeakoulutus as onko_avoin_korkeakoulutus,
        tunniste,
        opinnontyyppikoodiuri as opinnon_tyyppi_koodiuri,
        korkeakoulutustyypit as korkeakoulutus_tyypit,
        osaamisalakoodiuri as osaamisala_koodiuri,
        erikoistumiskoulutuskoodiuri as erikoistumiskoulutus_koodiuri,
        linkkieperusteisiin as linkki_eperusteisiin,
        teemakuva,
        eperusteid,
        luokittelutermit
    from koulutus
)

select * from final
