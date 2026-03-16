{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid','priorisoitu_kansalaisuus']}
    ]
    )
}}

with henkilo as not materialized (
    select
        henkilo_oid,
        kansalaisuus
    from {{ ref('int_onr_henkilo') }}
),

maa_valtioryhma as (
    select distinct maa_koodiarvo
    from {{ ref('int_koodisto_maa_valtioryhma') }}
    where valtioryhma_koodiarvo in ('EU', 'ETA')
),

maat as (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_maa_2') }}
    where viimeisin_versio
),

kansalaisuudet as materialized (
    select
        henk.henkilo_oid,
        elem.value ->> 0 as kansalaisuus
    from henkilo as henk
    cross join lateral jsonb_array_elements(henk.kansalaisuus) as elem (value)
),

jarjestys as (
    select
        kans.henkilo_oid,
        kans.kansalaisuus,
        case
            when kans.kansalaisuus = '246' then 1
            when maav.maa_koodiarvo is not null then 2
            else 3
        end as kansalaisuusluokka,
        row_number() over (
            partition by kans.henkilo_oid
            order by
                case
                    when kans.kansalaisuus = '246' then 1
                    when maav.maa_koodiarvo is not null then 2
                    else 3
                end,
                kans.kansalaisuus
        ) as haluttu_kansalaisuus
    from kansalaisuudet as kans
    left join maa_valtioryhma as maav
        on kans.kansalaisuus = maav.maa_koodiarvo
),

/*
kansalaisuus_jarjestys as (
    select
        henkilo_oid,
        kansalaisuus,
        case
            when kansalaisuus = '246' then 1
            when kansalaisuus in (
                select maa_koodiarvo from maa_valtioryhma
            ) then 2
            else 3
        end
        as jarjestys
    from (
        select
            henkilo_oid,
            (jsonb_array_elements(kansalaisuus) ->> 0) as kansalaisuus --noqa: CV11
        from henkilo
    )
),

haluttu_kansalaisuus as (
    select
        henkilo_oid,
        kansalaisuus,
        jarjestys as kansalaisuusluokka,
        row_number() over (
            partition by henkilo_oid
            order by jarjestys
        ) as haluttu_kansalaisuus
    from kansalaisuus_jarjestys
),
*/

final as (
    select
        jarj.henkilo_oid,
        jarj.kansalaisuus,
        jsonb_build_object(
            'en', maat.nimi_en,
            'sv', maat.nimi_sv,
            'fi', maat.nimi_fi
        ) as kansalaisuus_nimi,
        jarj.kansalaisuusluokka,
        jarj.haluttu_kansalaisuus = 1 as priorisoitu_kansalaisuus
    from jarjestys as jarj
    left join maat on jarj.kansalaisuus = maat.koodiarvo
)

select * from final
