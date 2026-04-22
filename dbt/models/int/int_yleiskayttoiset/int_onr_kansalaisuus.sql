{{
  config(
    materialized = 'incremental',
    unique_key = 'henkilo_oid',
    incremental_strategy= 'delete+insert',
     indexes = [
        {'columns': ['henkilo_oid','priorisoitu_kansalaisuus']},
        {'columns': ['muokattu']}
    ],
    post_hook = [
        "create index if not exists ix_kansalaisuus_priorisoitu on {{ this }} (henkilo_oid) where priorisoitu_kansalaisuus = true;"
    ]
  )
}}

with henkilo as not materialized (
    select
        henkilo_oid,
        kansalaisuus,
        muokattu
    from {{ ref('int_onr_henkilo') }}
    {% if is_incremental() %}
      where muokattu >= coalesce((select max(muokattu) from {{ this }}), '1900-01-01')
    {% endif %}
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
        henk.muokattu,
        elem.value ->> 0 as kansalaisuus
    from henkilo as henk
    cross join lateral jsonb_array_elements(henk.kansalaisuus) as elem (value)
),

jarjestys as (
    select
        kans.henkilo_oid,
        kans.kansalaisuus,
        kans.muokattu,
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

final as (
    select
        jarj.henkilo_oid,
        jarj.kansalaisuus,
        jarj.muokattu,
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
