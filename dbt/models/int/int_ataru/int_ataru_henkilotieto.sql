with raw as (
    select
        *,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as _row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

kansalaisuus as (
    select * from {{ ref('int_ataru_kansalaisuus') }}
    where haluttu_kansalaisuus = 1
),

henkilo_tieto as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['oid',
            'henkilo_oid']
            ) }} as henkilotieto_id,
        oid as hakemus_oid,
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
        puhelin
    from raw
    where _row_nr = 1
),

final as (
    select
        heti.*,
        kans.kansalaisuus
    from henkilo_tieto as heti
    inner join kansalaisuus as kans on heti.henkilotieto_id = kans.henkilotieto_id
)

select * from final
