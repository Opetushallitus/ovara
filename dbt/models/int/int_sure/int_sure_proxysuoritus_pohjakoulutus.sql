{{
    config(
        materialized = 'table',
    )
}}

with raw as (
    select * from {{ ref('int_sure_proxysuoritus') }}
    where keyvalues ? 'POHJAKOULUTUS'
),

koodisto as (
    select * from {{ ref('int_koodisto_pohjakoulutustoinenaste') }}
    where viimeisin_versio
),

pohjakoulutus as (
    select
        raw1.hakemusoid as hakemus_oid,
        (raw1.keyvalues ->> 'POHJAKOULUTUS')::int as pohjakoulutus
    from raw as raw1
),


final as (
    select
        poko.hakemus_oid,
        poko.pohjakoulutus,
        kood.koodinimi as pohjakoulutus_nimi
    from pohjakoulutus as poko
    left join koodisto as kood on poko.pohjakoulutus = kood.koodiarvo
)

select * from final
