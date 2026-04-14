{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['muokattu']}
    ],
    pre_hook = [
        "create index if not exists idx_onr_updated_expr on {{ source('ovara', 'onr_henkilo') }} ((data ->> 'updated'));"
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'onr_henkilo') }}
    {% if is_incremental() %}
    -- process only rows where updated is newer than newest timestamp in dw
        where data ->> 'updated'> (
            select coalesce(
                to_char(max(muokattu) - interval '7 days','YYYY-MM-DD"T"HH24:MI:SS"Z"'),
                '1899-12-31T00:00:00Z'
                )
            from {{ source('yleiskayttoiset', 'dw_onr_henkilo') }}
            )
    --end of incremental logic #}
    {% endif %}

),

final as (
  select
        data.henkilo_oid,
        data.master_oid,
        data.etunimet,
        data.sukunimi,
        data.hetu,
        data.kotikunta,
        data.syntymaaika,
        data.aidinkieli,
        array_to_json(string_to_array((data.kansalaisuus), ','))::jsonb as kansalaisuus,
        data.sukupuoli,
        data.turvakielto,
        data.yksiloityvtj,
        data.created as luotu,
        data.updated as  muokattu
    from source
    cross join lateral jsonb_to_record(data) as data (
    	henkilo_oid text,
    	master_oid text,
    	etunimet text,
    	sukunimi text,
    	hetu text,
    	kotikunta text,
    	syntymaaika date,
    	aidinkieli text,
    	sukupuoli int,
    	turvakielto boolean,
    	yksiloityvtj boolean,
    	created timestamptz,
    	updated timestamptz,
    	kansalaisuus text
    )
)

select * from final
