with onr_henkilo as (
    select * from {{ ref('int_onr_henkilo') }}
),

ataru_henkilo as (
    select henkilo_oid from {{ ref('int_ataru_hakemus') }}
),

sure_henkilo as (
    select henkilo_oid from {{ ref('int_sure_suoritus') }}
),

ovara_henkilot as (
    select distinct henkilo_oid from ataru_henkilo
    union
    select distinct henkilo_oid from sure_henkilo
),

kunta as (
    select * from {{ ref('int_koodisto_kunta') }}
    where viimeisin_versio
),

final as (
    select
        henk.henkilo_oid as oppija_oid,
        coalesce(henk.master_oid, henk.henkilo_oid) as master_oid,
        henk.hetu,
        henk.sukupuoli::text,
        henk.syntymaaika,
        henk.sukunimi,
        henk.etunimet,
        henk.aidinkieli,
        regexp_replace(henk.kansalaisuus::text, '\[|"|]|[[:blank:]]', '', 'g') as kansalaisuus,
        henk.turvakielto,
        henk.kotikunta,
        kunt.koodinimi ->> 'fi' as kotikunta_fi,
        kunt.koodinimi ->> 'sv' as kotikunta_sv,
        henk.yksiloityvtj as yksiloity
    from onr_henkilo as henk
    left join kunta as kunt on henk.kotikunta = kunt.koodiarvo
    inner join ovara_henkilot as hlot on henk.henkilo_oid = hlot.henkilo_oid
)

select * from final
