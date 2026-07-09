{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid']}
    ]
    )
}}

with raw as (
	select distinct on (master_oid)
		*
	from {{ ref('int_ylioppilas_rivit') }}
    where on_ylioppilas
	order by master_oid, valmistumis_paiva asc
),

onr as (
    select
        master_oid,
        henkilo_oid
    from {{ ref('int_onr_henkilo') }}
),

final as (
	select
        onr.henkilo_oid,
        raw.on_ylioppilas,
        extract(year from raw.valmistumis_paiva)::int as valmistumis_vuosi
	from raw
	join onr on raw.master_oid = onr.master_oid
)

select * from final
