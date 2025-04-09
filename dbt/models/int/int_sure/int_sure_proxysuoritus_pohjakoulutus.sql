{{
    config(
        materialized = 'table',
    )
}}

with raw as (
    select * from {{ ref('dw_sure_proxysuoritus') }}
    where keyvalues ? 'POHJAKOULUTUS'
),

koodisto as (
    select * from {{ ref('int_koodisto_pohjakoulutustoinenaste') }}
    where viimeisin_versio
),

final as (
    select
        raw1.hakemusoid as hakemus_oid,
        (raw1.keyvalues ->> 'POHJAKOULUTUS')::int as pohjakoulutus,
        kood.koodinimi as pohjakoulutus_nimi
    from raw as raw1
    left join koodisto as kood on raw1.pohjakoulutus::int = kood.koodiarvo
)

select * from final
