{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['koulutus_oid']},
            {'columns':['organisaatio_oid']},
        ]
    )
}}

with toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

int as (
    select
        toteutus_oid,
        toteutus_nimi,
        tunniste as ulkoinen_tunniste,
        tila,
        organisaatio_oid,
        koulutus_oid,
        koulutuksenalkamiskausi as koulutuksen_alkamiskausi,
        suunniteltukestovuodet,
        suunniteltukestokuukaudet,
        koulutuksenalkamiskausi ->> 'alkamiskausityyppi' as koulutuksenalkamiskausityyppi,
        koulutuksenalkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' as koulutuksenalkamiskausikoodiuri,
        (koulutuksenalkamiskausi ->> 'koulutuksenAlkamisvuosi')::int as koulutuksenalkamisvuosi,
        (koulutuksenalkamiskausi ->> 'koulutuksenAlkamispaivamaara')::date as koulutuksenalkamispaivamaara,
        koulutuksenalkamiskausi ->> 'henkilokohtaisenSuunnitelmanLisatiedot' as henkilokohtaisensunnitelmanlisatiedot
    from toteutus
),

step2 as (
    select
        *,
        case
            when koulutuksenalkamiskausityyppi = 'alkamiskausi ja -vuosi' then koulutuksenalkamiskausikoodiuri
            when
                koulutuksenalkamiskausityyppi = 'tarkka alkamisajankohta'
                and date_part('month', koulutuksenalkamispaivamaara) <= 6 then 'kausi_k#1'
            when
                koulutuksenalkamiskausityyppi = 'tarkka alkamisajankohta'
                and date_part('month', koulutuksenalkamispaivamaara) >= 6 then 'kausi_s#1'
        end as koulutuksen_alkamiskausi_koodiuri,
        case
            when
                koulutuksenalkamiskausityyppi = 'alkamiskausi ja -vuosi'
                then koulutuksenalkamisvuosi
            when
                koulutuksenalkamiskausityyppi = 'tarkka alkamisajankohta'
                then date_part('year', koulutuksenalkamispaivamaara)
        end as koulutuksen_alkamisvuosi,
        henkilokohtaisensunnitelmanlisatiedot as henkilokohtaisen_sunnitelman_lisatiedot
    from int
),

final as (
    select
        toteutus_oid,
        toteutus_nimi,
        ulkoinen_tunniste,
        tila,
        organisaatio_oid,
        koulutus_oid,
        koulutuksen_alkamiskausi,
        suunniteltukestovuodet,
        suunniteltukestokuukaudet,
        koulutuksenalkamiskausityyppi as koulutuksen_alkamiskausi_tyyppi,
        koulutuksen_alkamiskausi_koodiuri,
        koulutuksen_alkamisvuosi,
        henkilokohtaisen_sunnitelman_lisatiedot
    from step2
)

select * from final
