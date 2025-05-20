{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['toteutus_oid','haku_oid']}
    ]
    )
}}

with toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

hakukohde as (
    select distinct
        toteutus_oid,
        haku_oid
    from {{ ref('int_hakukohde') }}
),

koulutuksen_alkamiskausi_rivit as (
    select
        toteutus_oid,
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
    from toteutus
    where koulutuksen_alkamiskausi is not null
),

koulutuksen_alkamiskausi_koodi as (
    select
        toteutus_oid,
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
    from koulutuksen_alkamiskausi_rivit
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            [
                'tote.toteutus_oid',
                'hako.haku_oid',
            ]
        ) }} as toteutus_id,
        tote.toteutus_oid,
        hako.haku_oid,
        koak.koulutuksen_alkamiskausikoodi
    from toteutus as tote
    left join koulutuksen_alkamiskausi_koodi as koak on tote.toteutus_oid = koak.toteutus_oid
    left join hakukohde as hako on tote.toteutus_oid = hako.toteutus_oid
    where koulutuksen_alkamiskausikoodi is not null
)

select * from final
