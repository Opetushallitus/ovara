--{{ ref('pub_fct_hakemus') }}
{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_oid','hakemus_oid']}
    ]
    )
}}

with onr as not materialized (
    select * from {{ ref('int_onr_henkilo') }}
),

ataru as not materialized (
    select * from {{ ref('int_ataru_hakemus') }}
),

kansalaisuus as not materialized (
    select * from {{ ref('int_onr_kansalaisuus') }}
    where priorisoitu_kansalaisuus
),

kunta as (
    select * from {{ ref('int_koodisto_kunta') }}
),

maa as (
    select * from {{ ref('int_koodisto_maa_2') }}
),

int as (
    select
        atar.henkilo_oid,
        atar.hakemus_oid,
        case
            when onr1.hetu is not null
                then onr1.etunimet
            else atar.etunimet
        end as etunimet,
        case
            when onr1.hetu is not null
                then onr1.sukunimi
            else atar.sukunimi
        end as sukunimi,
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
        onr1.turvakielto,
        onr1.hetu,
        onr1.syntymaaika
    from ataru as atar
    inner join onr as hmap on atar.henkilo_oid = hmap.henkilo_oid
    inner join onr as onr1 on hmap.master_oid = onr1.henkilo_oid
    left join kansalaisuus as kans on onr1.henkilo_oid = kans.henkilo_oid
    left join kunta as knta on atar.kotikunta = knta.koodiarvo
    left join maa as maa2 on atar.asuinmaa = maa2.koodiarvo

)

select
    {{ dbt_utils.generate_surrogate_key(['henkilo_oid', 'hakemus_oid']) }} as henkilo_hakemus_id,
    *
from int
