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

int as (
    select
        raw1.hakemusoid as hakemus_oid,
        (raw1.keyvalues ->> 'POHJAKOULUTUS')::int as pohjakoulutus
    from raw as raw1
),


final as (
    select
        int1.hakemus_oid,
        int1.pohjakoulutus,
        kood.koodinimi as pohjakoulutus_nimi
    from int as int1
    left join koodisto as kood on int1.pohjakoulutus::int = kood.koodiarvo
)

select * from final
