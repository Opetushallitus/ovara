{{
  config(
    materialized = 'table',
    post_hook = [
        " {{ create_pk('hakukohde_oid') }}"
    ]
    )
}}
with hakukohde as (
    select
        hakukohde_oid,
        toteutus_oid,
        haku_oid,
        jarjestyspaikka_oid
    from {{ ref('int_hakukohde') }}
),

hakukohde_nimet as (
    select
        oppilaitos,
        jarjestyspaikka_oid
    from {{ ref('int_organisaatio_hakukohteiden_nimet') }}
),
toteutus as (
    select
        toteutus_oid,
        koulutus_oid
    from {{ ref('int_kouta_toteutus') }}
),

koulutus as (
    select
        koulutus_oid,
        koulutuksetkoodiuri,
        johtaatutkintoon
    from {{ ref('int_kouta_koulutus') }}
),

haku as (
    select
        haku_oid,
        kohdejoukkokoodiuri,
        kohdejoukontarkennekoodiuri
    from {{ ref('int_haku') }}
),

alat_ja_asteet as (
    select
        versioitu_koodiuri,
        kansallinenkoulutusluokitus2016koulutusastetaso2
    from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
),

yos as (
    select organisaatio_oid from {{ ref('int_yos_poikkeukset') }}
),

koulutusaste as (
    select
        koulutus_oid,
        jsonb_agg(distinct b.kansallinenkoulutusluokitus2016koulutusastetaso2) as koulutustasot
    from koulutus a
    cross join lateral jsonb_array_elements_text(a.koulutuksetkoodiuri) as j(koodi)
    join int.int_koodisto_koulutus_alat_ja_asteet b on j.koodi = b.versioitu_koodiuri
    group by a.koulutus_oid
),

rows as (
	select
	a.hakukohde_oid,
    a.jarjestyspaikka_oid,
	d.kohdejoukkokoodiuri,
	d.kohdejoukontarkennekoodiuri,
	c.johtaatutkintoon,
	e.koulutustasot
	from hakukohde a
	join toteutus b on a.toteutus_oid =b.toteutus_oid
	join koulutus c on b.koulutus_oid =c.koulutus_oid
	join haku d on a.haku_oid =d.haku_oid
	join koulutusaste e on c.koulutus_oid = e.koulutus_oid
),

ei_yos_hakukohteet as materialized (
	select a.jarjestyspaikka_oid
	from hakukohde_nimet a
	join yos b on a.oppilaitos  = b.organisaatio_oid
),

final as (
select
	hakukohde_oid,
	koulutustasot,
	koulutustasot ?| ARRAY['62', '63', '71', '72']
		and johtaatutkintoon
		and coalesce(kohdejoukontarkennekoodiuri not in ('haunkohdejoukontarkenne_010#1', 'haunkohdejoukontarkenne_3#1'), true)
		and coalesce (kohdejoukkokoodiuri = 'haunkohdejoukko_12#1',false)
		and not exists (
			select 1 from ei_yos_hakukohteet e
            where e.jarjestyspaikka_oid = rows.jarjestyspaikka_oid)
	as yos
from rows
)

select * from final
