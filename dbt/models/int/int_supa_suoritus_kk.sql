with raw as (
	select
        henkilo_oid,
        s.suoritus
	from {{ ref('dw_supa_opiskeluoikeus') }} as opoi
    cross join lateral jsonb_array_elements(
        (opoi.data -> 'kkSuorituksetFlat')::jsonb
    ) as s(suoritus)
),

final as (
    select
        henkilo_oid,
        suoritus ->> 'tunniste' as tunniste,
        suoritus ->> 'opiskeluoikeusTyyppi' as tyyppi,
        suoritus -> 'metadata' ->> 'lahdejarjestelma' as lahdejarjestelma,
        suoritus ->> 'supaTila' as tila,
        case
            when suoritus -> 'metadata' ->> 'lahdejarjestelma' = 'VIRTA'
            then suoritus -> 'opiskeluoikeusVirtaTila' ->> 'arvo'
        end as lahdejarjestelman_tila,
        (suoritus ->> 'opiskeluoikeusAlkuPvm')::date as alku_pvm,
        (suoritus ->> 'opiskeluoikeusLoppuPvm')::date as paattymis_pvm,
        suoritus ->> 'opiskeluoikeusKieli' as suorituskieli
    from raw
)

select * from final
