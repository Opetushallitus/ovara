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

arvosana_rows as (
    select
        henkilo_oid,
        aineet_elem -> 'koodi' ->> 'arvo' as aine,
        aineet_elem -> 'arvosana' ->> 'arvo' as arvosana
    from opoi
    cross join lateral (
        select value as root_elem
        from jsonb_array_elements(opoi.data -> 'yoOpiskeluoikeudet')
        where value -> 'yoTutkinto' ->> 'supaTila' = 'VALMIS'
    ) as yooo
    cross join lateral jsonb_array_elements(root_elem -> 'yoTutkinto' -> 'aineet') as aineet_elem
),

paras_arvosana as (
    select
        henkilo_oid,
        aine,
        coalesce(
        (array['L','E','M','C','B','A','I'])[
            min(array_position(array['L','E','M','C','B','A','I'], arvosana))
        ],
        max(arvosana)
       ) as arvosana
    from arvosana_rows
    group by henkilo_oid, aine
),

arvosanat as (
	select
	    henkilo_oid,
	    jsonb_object_agg(aine, arvosana) as arvosanat
	from paras_arvosana
	group by henkilo_oid
),

arvosanat_master as (
    select
        onr1.master_oid,
        arsa.arvosanat
    from arvosanat as arsa
    inner join onr as onr1 on arsa.henkilo_oid = onr1.henkilo_oid
),

final as (
    select
        onr1.henkilo_oid,
        arma.arvosanat
    from arvosanat_master as arma
    inner join lateral (
        select onr.henkilo_oid
        from onr
        where onr.master_oid = arma.master_oid
    ) as onr1 on true
)

select * from final
