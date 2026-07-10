{{
  config(
    materialized = 'table'
    )
}}

with source as (
	select
        henkilo_oid,
        data
	from {{ ref('int_supa_opiskeluoikeus') }}
	where jsonb_array_length(data -> 'yoOpiskeluoikeudet') > 0
),

onr as (
	select
		master_oid,
		henkilo_oid
	from {{ ref('int_onr_henkilo') }}
),

final as (
select
		b.master_oid,
        a.henkilo_oid,
		upper(yoop.obj -> 'yoTutkinto' ->> 'supaTila') = 'VALMIS' as on_ylioppilas,
		(yoop.obj -> 'yoTutkinto' ->> 'valmistumisPaiva')::date as valmistumis_paiva
	from source a
	join onr b on a.henkilo_oid = b.henkilo_oid
	cross join lateral (select jsonb_array_elements(data -> 'yoOpiskeluoikeudet') ) as yoop(obj)
)

select * from final
