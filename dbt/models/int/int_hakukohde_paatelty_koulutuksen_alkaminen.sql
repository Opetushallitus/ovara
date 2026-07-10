{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('hakukohde_oid') }}"
    ]
    )
}}

with hakukohde as (
    select
        hakukohde_oid,
        haku_oid,
        toteutus_oid,
        koulutuksen_alkamiskausi
    from {{ ref('int_hakukohde') }}
    where tila != 'poistettu'
),

haku as (
    select
        haku_oid,
        koulutuksen_alkamiskausi
    from {{ ref('int_haku') }}
),

toteutus as (
    select
        toteutus_oid,
        koulutuksen_alkamiskausi
    from {{ ref('int_kouta_toteutus') }}
),


alkamiskausi as (
	select
		hako.hakukohde_oid,
		coalesce (
            hako.koulutuksen_alkamiskausi,
            haku.koulutuksen_alkamiskausi,
            tote.koulutuksen_alkamiskausi
        ) as paatelty_alkamiskausi
	from hakukohde as hako
	left join haku on hako.haku_oid =haku.haku_oid
	left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
),

final as (
	select
		hakukohde_oid,
		case
			when paatelty_alkamiskausi ->> 'alkamiskausityyppi' = 'tarkka alkamisajankohta' then  (paatelty_alkamiskausi ->> 'koulutuksenAlkamispaivamaara')::date
			when paatelty_alkamiskausi ->> 'alkamiskausityyppi' = 'alkamiskausi ja -vuosi' then
			case
				when paatelty_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' = 'kausi_k#1' then make_date((paatelty_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int,1,1)
				when paatelty_alkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri' = 'kausi_s#1' then make_date((paatelty_alkamiskausi ->> 'koulutuksenAlkamisvuosi')::int,8,1)
				end
		end as koulutus_alkaa,
		paatelty_alkamiskausi
	from
	alkamiskausi
)

select * from final
where koulutus_alkaa is not null

