{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['haku_oid']}
    ]
    )
}}

with haku as (
    select * from {{ ref('int_kouta_haku') }}
),

parameter as (
    select * from {{ ref('int_ohjausparametrit_parameter') }}
),

koulutuksen_alkamiskausi_rivi as (
    select
        haku_oid,
        case
            when koulutuksen_alkamiskausi ->> 'alkamiskausityyppi' = 'alkamiskausi ja -vuosi'
                then (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int
            when koulutuksen_alkamiskausi ->> 'alkamiskausityyppi' = 'tarkka alkamisajankohta'
                then date_part('year', (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz)::int
            else -1
        end as alkamisvuosi,
        case
            when koulutuksen_alkamiskausi ->> 'alkamiskausityyppi' = 'alkamiskausi ja -vuosi'
                then koulutuksen_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri'
            when koulutuksen_alkamiskausi ->> 'alkamiskausityyppi' = 'tarkka alkamisajankohta'
                then
                    case
                        when
                            date_part(
                                'month', (koulutuksen_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz
                            )::int < 8
                            then 'kausi_k#1'
                        else 'kausi_s#1'
                    end
        end as kausi
    from haku
    where koulutuksen_alkamiskausi is not null
),

koulutuksen_alkamiskausi_koodi as (
    select distinct
        haku_oid,
        case
            when alkamisvuosi = -1
                then jsonb_build_object('type', 'henkkoht')
            when alkamisvuosi is null
                then '{}'
            else jsonb_build_object(
                'type', 'kausivuosi',
                'koulutuksenAlkamisvuosi', alkamisvuosi,
                'koulutuksenAlkamiskausiKoodiUri', kausi
            )
        end as koulutuksen_alkamiskausikoodi
    from koulutuksen_alkamiskausi_rivi
),

final as (
    select
        haku.haku_oid,
        haku.haku_nimi,
        haku.externalid as ulkoinen_tunniste,
        haku.tila,
        haku.organisaatiooid as organisaatio_oid,
        haku.hakutapakoodiuri,
        haku.hakukohteenliittamisentakaraja,
        haku.hakukohteenmuokkaamisentakaraja,
        haku.hakukohteenliittajaorganisaatiot,
        haku.kohdejoukkokoodiuri,
        haku.kohdejoukontarkennekoodiuri,
        haku.koulutuksen_alkamiskausi,
        koak.koulutuksen_alkamiskausikoodi,
        haku.hakuajat,
        haun_tyyppi,
        para.vastaanotto_paattyy,
        para.hakijakohtainen_paikan_vastaanottoaika,
        para.jarjestetyt_hakutoiveet,
        haku.hakutapakoodiuri = 'hakutapa_05#1' as siirtohaku
    from haku
    left join parameter as para on haku.haku_oid = para.haku_oid
    left join koulutuksen_alkamiskausi_koodi as koak on haku.haku_oid = koak.haku_oid
)

select * from final
