with raw as (
	select
		henkilo_oid,
		data,
		s.suoritus
	from {{ ref('dw_supa_opiskeluoikeus') }} as opoi
    cross join lateral jsonb_array_elements(
        (opoi.data -> 'perusopetuksenOpiskeluoikeudet')::jsonb
    ) as s(suoritus)
),

final as (
    select
        henkilo_oid,
        suoritus ->> 'tunniste' as tunniste,
        suoritus ->> 'entiteetinTyyppi' as tyyppi,
        suoritus #>> '{metadata, lahdejarjestelma}' as lahdejarjestelma,
        suoritus ->> 'tila' as tila,
        suoritus #>> '{suoritukset, 0, koskiTila, arvo}' as lahdejarjestelman_tila,
        (suoritus #>> '{suoritukset,0, aloitusPaivamaara}')::date as alku_pvm,
        (suoritus #>> '{suoritukset, 0, vahvistusPaivamaara}')::date as paattymis_pvm,
        suoritus #>> '{suoritukset, 0, suoritusKieli, arvo}' as suorituskieli,
        suoritus #>> '{suoritukset, 0, koulusivistyskieli, 0, arvo}' as koulusivistyskieli,
        suoritus #>> '{suoritukset, 0, yksilollistaminen}' as yksilollistaminen
    from raw
)

select * from final
