{{
  config(
    materialized = 'incremental',
    unique_key = 'henkilo_oid',
    incremental_strategy= 'delete+insert',
    indexes = [
        {'columns': ['muokattu']},
        {'columns': ['henkilo_oid']}
    ]
    )
}}

with henkilo as (
    select
        henkilo_oid,
        kansalaisuus,
        muokattu
    from {{ ref('int_onr_henkilo') }}
    {% if is_incremental() %}
      where muokattu >= coalesce((select max(muokattu) from {{ this }}), '1900-01-01')
    {% endif %}
),

maa as (
    select
        koodiarvo,
        koodinimi
    from {{ ref('int_koodisto_maa_2') }}
    where viimeisin_versio
),

final as (
    select
        henk.henkilo_oid,
        henk.muokattu,
        jsonb_agg(maa.koodinimi) as kansalaisuudet_nimi
    from
        henkilo as henk
    left join
        lateral
        jsonb_array_elements_text(henk.kansalaisuus) as kans (kansalaisuus)
        on true
    left join maa
        on
            kans.kansalaisuus = maa.koodiarvo
    group by
        henk.henkilo_oid,
        henk.muokattu
)

select * from final
