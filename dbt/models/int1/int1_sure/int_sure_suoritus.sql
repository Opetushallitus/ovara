{{
    config(
        materialized = 'incremental',
        unique_key = ['resourceid'],
        incremental_strategy = 'merge',
        indexes = [
            {'columns':['resourceid','muokattu']}
        ]
    )
}}

with suoritus as not materialized (
    select * from {{ ref('dw_sure_suoritus') }}
    {%- if target.name == 'prod' and is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce (
	    (
    		select  start_time from {{ source('ovara', 'completed_dbt_runs') }}
	      	where raw_table = 'sure_suoritus'
	    ),
        '1900-01-01'
    )
    {% endif %}
),

final as (
    select
        suo1.resourceid,
        suo1.komo,
        suo1.myontaja,
        suo1.tila,
        suo1.valmistuminen,
        suo1.henkilooid as henkilo_oid,
        suo1.yksilollistaminen,
        suo1.suorituskieli,
        suo1.muokattu,
        suo1.poistettu,
        suo1.source,
        suo1.vahvistettu,
        suo1.arvot
    from suoritus as suo1
    left join suoritus as suo2
        on
            suo1.resourceid = suo2.resourceid
            and suo1.muokattu < suo2.muokattu
    {% if is_incremental() %}
        left join {{ this }} as suo3
            on
                suo1.resourceid = suo3.resourceid
    {% endif %}
    where
        suo2.resourceid is null
        {% if is_incremental() %}
            and (
                suo1.muokattu > suo3.muokattu
                or suo3 is null
            )
        {% endif %}

)

select * from final
