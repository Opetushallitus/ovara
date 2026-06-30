{{
    config(
        materialized = 'table',
    )
}}

with koulutus as (
    select
        hakemusoid as hakemus_oid,
        (keyvalues ->> 'POHJAKOULUTUS')::int as pohjakoulutus
    from {{ ref('int_sure_proxysuoritus') }} a
        where keyvalues ? 'POHJAKOULUTUS' /*
        and exists (select 1 from {{ ref('int_sure_haut') }} b where a.hakuoid = b.haku_oid)

    union all

    select
        hakemus_oid,
        (keyvalues ->> 'POHJAKOULUTUS')::int
    from {{ ref('int_supa_valintadata') }} a
        where keyvalues ? 'POHJAKOULUTUS'
        and not exists (select 1 from {{ ref('int_sure_haut') }} b where a.haku_oid = b.haku_oid)
*/),

koodisto as (
    select
        koodiarvo,
        koodinimi
    from {{ ref('int_koodisto_pohjakoulutustoinenaste') }}
    where viimeisin_versio
),

final as (
	select
		hakemus_oid,
		pohjakoulutus,
		kood.koodinimi as pohjakoulutus_nimi
	from koulutus as koul
	join koodisto as kood on koul.pohjakoulutus=kood.koodiarvo
)

select * from final
