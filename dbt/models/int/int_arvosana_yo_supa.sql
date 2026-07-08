{{
  config(
    materialized = 'table',
    post_hook = "{{ create_pk('henkilo_oid')}}"
    )
}}

with opoi as (
	select
		henkilo_oid,
		data
	from {{ ref('int_supa_opiskeluoikeus') }}
	where jsonb_array_length(data -> 'yoOpiskeluoikeudet') > 0
),

onr as (
	select
		henkilo_oid,
		master_oid
	from {{ ref('int_onr_henkilo') }}
),

arvosanat as (
    select
        henkilo_oid,
        jsonb_object_agg (
        aineet_elem -> 'koodi' ->> 'arvo',
        aineet_elem -> 'arvosana' ->> 'arvo'
        ) as arvosanat
    from opoi
    cross join lateral (
        select value as root_elem from jsonb_array_elements(opoi.data -> 'yoOpiskeluoikeudet')  where value -> 'yoTutkinto' ->> 'supaTila' = 'VALMIS'
        )
    cross join lateral jsonb_array_elements(root_elem -> 'yoTutkinto' -> 'aineet') as aineet_elem
    group by henkilo_oid
),

arvosanat_master as (
	select
		b.master_oid,
		a.arvosanat
	from arvosanat a
	join onr b on a.henkilo_oid=b.henkilo_oid
),

final as (
    select
        onr1.henkilo_oid,
        arma.arvosanat
    from arvosanat_master arma
    join lateral (
		select
			onr.henkilo_oid
		from onr
		where onr.master_oid = arma.master_oid
	) onr1 on true
)

select * from final