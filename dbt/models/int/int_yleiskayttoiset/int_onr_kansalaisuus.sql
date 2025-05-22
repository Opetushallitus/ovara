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

maat as not materialized (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_maa_2') }}
    where viimeisin_versio
),

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

final as (
    select
        henkilo_oid,
        kansalaisuus,
        jsonb_build_object(
            'en', maat.nimi_en,
            'sv', maat.nimi_sv,
            'fi', maat.nimi_fi
        ) as kansalaisuus_nimi,
        kansalaisuusluokka,
        haluttu_kansalaisuus = 1 as priorisoitu_kansalaisuus
    from haluttu_kansalaisuus as kans
    left join maat on kans.kansalaisuus = maat.koodiarvo
)

select * from final
