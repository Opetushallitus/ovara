{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['haun_tyyppi']},
        {'columns': ['koulutuksen_alkamiskausi'], 'type': 'gin' }
    ]
    )
}}

with haku as (
    select
        haku_oid,
        haku_nimi,
                case
            when koulutuksen_alkamiskausikoodi = '{}'::jsonb then null
            else koulutuksen_alkamiskausikoodi
        end as koulutuksen_alkamiskausikoodi,
        haun_tyyppi
    from {{ ref('int_haku') }} where tila != 'poistettu'
),

toteutus as (
    select distinct
        haku_oid,
        toteutus_oid,
        case
            when koulutuksen_alkamiskausikoodi = '{}'::jsonb then null
            else koulutuksen_alkamiskausikoodi
        end as koulutuksen_alkamiskausikoodi
    from {{ ref('int_toteutus_koulutuksen_alkamiskausi') }}
    where haku_oid is not null
),

hakukohde as (
    select
        haku_oid,
        toteutus_oid,
        hakukohde_oid,
                case
            when koulutuksen_alkamiskausikoodi = '{}'::jsonb then null
            else koulutuksen_alkamiskausikoodi
        end as koulutuksen_alkamiskausikoodi
    from {{ ref('int_hakukohde') }}
),

alkamisajankohta_rivit as (
    select
        haku_oid,
        koulutuksen_alkamiskausikoodi as koulutuksen_alkamiskausikoodi_haku,
        null as koulutuksen_alkamiskausikoodi_haku2,
        null as koulutuksen_alkamiskausikoodi_hako,
        null as koulutuksen_alkamiskausikoodi_tote,
        null as hakukohde_oid,
        null as toteutus_oid
    from haku

    union
    select
        haku.haku_oid,
        null as koulutuksen_alkamiskausikoodi_haku,
        haku.koulutuksen_alkamiskausikoodi as koulutuksen_alkamiskausikoodi_haku2,
        hako.koulutuksen_alkamiskausikoodi as koulutuksen_alkamiskausikoodi_hako,
        tote.koulutuksen_alkamiskausikoodi as koulutuksen_alkamiskausikoodi_tote,
        hako.hakukohde_oid,
        tote.toteutus_oid
    from haku
    left join hakukohde as hako on haku.haku_oid = hako.haku_oid
    left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
),

alkamisajankohta as (
select distinct
	haku_oid,
	coalesce (
		case
			when koulutuksen_alkamiskausikoodi_haku is not null then koulutuksen_alkamiskausikoodi_haku
			when koulutuksen_alkamiskausikoodi_hako is not null then koulutuksen_alkamiskausikoodi_hako
			when koulutuksen_alkamiskausikoodi_haku2 is null then koulutuksen_alkamiskausikoodi_tote
	end,
	'{"type": "eialkamiskautta"}'::jsonb
	)
	as koulutuksen_alkamiskausi
    from alkamisajankohta_rivit


),

final as (
select
    haku.haku_oid,
    haku.haku_nimi,
    jsonb_agg (alko.koulutuksen_alkamiskausi) as koulutuksen_alkamiskausi,
    haku.haun_tyyppi
from haku
left join alkamisajankohta as alko on haku.haku_oid = alko.haku_oid
group by
    haku.haku_oid,
    haku.haku_nimi,
    haku.haun_tyyppi
)

select * from final
