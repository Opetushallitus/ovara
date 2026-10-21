with raw as (
	select
		henkilo_oid,
		data,
		s.suoritus
	from {{ ref('dw_supa_opiskeluoikeus') }} as opoi
    cross join lateral jsonb_array_elements(
        (opoi.data -> 'yoOpiskeluoikeudet')::jsonb
    ) as s(suoritus)
),

final as (
    select
        henkilo_oid,
        suoritus ->> 'tunniste' as tunniste,
        suoritus ->> 'entiteetinTyyppi' as tyyppi,
        suoritus #>> '{metadata, lahdejarjestelma}' as lahdejarjestelma,
        suoritus #>> '{yoTutkinto, supaTila}' as tila,
        (suoritus #>> '{yoTutkinto, valmistumisPaiva}')::date as paattymis_pvm,
        suoritus #>> '{yoTutkinto, suoritusKieli, arvo}' as suorituskieli
    from raw
)

select * from final
