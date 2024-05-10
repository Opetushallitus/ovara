{{
  config(
    indexes=[{'columns':['henkilotieto_id','haluttu_kansalaisuus']}]
    )
}}

with raw as (
    select
        oid as hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as _row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

maa_valtioryhma as (
    select distinct maa_koodiarvo
    from {{ ref('int_koodisto_maa_valtioryhma') }}
    where valtioryhma_koodiarvo in ('EU', 'ETA')
),

kansalaisuus_riveille as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'henkilo_oid']
            ) }} as henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        (jsonb_array_elements(kansalaisuus) ->> 0)::int as kansalaisuus --noqa: CV11
    from raw where _row_nr = 1
),

kansalaisuus_jarjestys as (
    select
        henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        case
            when kansalaisuus = 246 then 1
            when kansalaisuus in (
                select maa_koodiarvo from maa_valtioryhma
            ) then 2
            else 3
        end
        as jarjestys
    from kansalaisuus_riveille
),

final as (
    select
        henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        kansalaisuus,
        row_number() over (partition by henkilotieto_id order by jarjestys) as haluttu_kansalaisuus
    from kansalaisuus_jarjestys
)

select * from final
