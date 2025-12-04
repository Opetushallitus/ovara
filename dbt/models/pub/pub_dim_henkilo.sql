--{{ ref('pub_fct_hakemus') }}
{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_hakemus_id']},
        {'columns':['henkilo_oid']}
    ]
    )
}}

with onr as not materialized (
    select
        henkilo_oid,
        master_oid,
        etunimet,
        sukunimi,
        aidinkieli,
        sukupuoli,
        kansalaisuus,
        turvakielto,
        hetu,
        syntymaaika
    from {{ ref('int_onr_henkilo') }}
),

ataru as not materialized (
    select
        henkilo_oid,
        hakemus_oid,
        lahiosoite,
        postinumero,
        postitoimipaikka,
        kotikunta,
        ulk_kunta,
        asuinmaa,
        sahkoposti,
        puhelin,
        pohjakoulutuksen_maa_toinen_aste,
        koulutusmarkkinointilupa,
        valintatuloksen_julkaisulupa,
        sahkoinenviestintalupa,
        hakemusmaksun_tila
    from {{ ref('int_ataru_hakemus') }}
),

kansalaisuus as not materialized (
    select
        henkilo_oid,
        kansalaisuus,
        kansalaisuus_nimi,
        kansalaisuusluokka
    from {{ ref('int_onr_kansalaisuus') }}
    where priorisoitu_kansalaisuus
),

kunta as (
    select * from {{ ref('int_koodisto_kunta') }}
    where viimeisin_versio
),

maa as (
    select * from {{ ref('int_koodisto_maa_2') }}
    where viimeisin_versio
),

kansalaisuudet as (
    SELECT
        h.henkilo_oid,
        jsonb_agg(m.koodinimi) AS kansalaisuudet_nimi
    FROM
        onr h
    LEFT JOIN LATERAL
        jsonb_array_elements_text(h.kansalaisuus) AS k(kansalaisuus)
        ON TRUE
    LEFT JOIN maa m
        ON k.kansalaisuus = m.koodiarvo
    AND m.viimeisin_versio
    GROUP BY
       h.henkilo_oid
),

int as (
    select
        atar.henkilo_oid,
        onr1.master_oid,
        atar.hakemus_oid,
        onr1.etunimet,
        onr1.sukunimi,
        atar.lahiosoite,
        atar.postinumero,
        atar.postitoimipaikka,
        atar.kotikunta,
        knta.koodinimi as kotikunta_nimi,
        atar.ulk_kunta as ulkomainen_kunta,
        atar.asuinmaa,
        maa2.koodinimi as asuinmaa_nimi,
        atar.sahkoposti,
        atar.puhelin,
        atar.pohjakoulutuksen_maa_toinen_aste,
        onr1.aidinkieli,
        case
            when onr1.aidinkieli = 'fi' then 'fi'
            when onr1.aidinkieli = 'sv' then 'sv'
            else 'muu'
        end as aidinkieliluokka,
        onr1.sukupuoli,
        atar.koulutusmarkkinointilupa,
        atar.valintatuloksen_julkaisulupa,
        atar.sahkoinenviestintalupa,
        kans.kansalaisuus,
        kans.kansalaisuus_nimi,
        kans.kansalaisuusluokka,
        onr1.kansalaisuus as kansalaisuudet,
        knss.kansalaisuudet_nimi,
        onr1.turvakielto,
        onr1.hetu,
        onr1.syntymaaika,
        atar.hakemusmaksun_tila
    from ataru as atar
    inner join onr as hmap on atar.henkilo_oid = hmap.henkilo_oid
    inner join onr as onr1 on hmap.master_oid = onr1.henkilo_oid
    left join kansalaisuus as kans on onr1.henkilo_oid = kans.henkilo_oid
    left join kunta as knta on atar.kotikunta = knta.koodiarvo
    left join maa as maa2 on atar.asuinmaa = maa2.koodiarvo
    left join kansalaisuudet as knss on hmap.henkilo_oid = knss.henkilo_oid

)

select
    {{ dbt_utils.generate_surrogate_key(['henkilo_oid', 'hakemus_oid']) }} as henkilo_hakemus_id,
    *
from int
