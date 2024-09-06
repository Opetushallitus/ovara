{{
  config(
    indexes = [
        {'columns': ['muokattu']},
    ],
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'henkilotieto_id',
    )
}}


with raw as (
    select * from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

kansalaisuus as (
    select * from {{ ref('int_ataru_kansalaisuus') }}
    where haluttu_kansalaisuus = 1
),

henkilo_tieto as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid', 'henkilo_oid']
            ) }} as henkilotieto_id,
        hakemus_oid,
        henkilo_oid,
        asiointikieli,
        etunimet,
        kutsumanimi,
        sukunimi,
        hetu,
        lahiosoite,
        postinumero,
        postitoimipaikka,
        ulk_kunta,
        kotikunta,
        asuinmaa,
        sukupuoli,
        sahkoposti,
        puhelin,
        muokattu,
        dw_metadata_dbt_copied_at
    from raw
),

final as (
    select
        heti.*,
        kans.kansalaisuus
    from henkilo_tieto as heti
    inner join kansalaisuus as kans on heti.henkilotieto_id = kans.henkilotieto_id
)

select * from final
