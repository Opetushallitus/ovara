{{
    config(
        materialized = 'incremental',
        unique_key = ['resourceid'],
        indexes = [
        ],
        incremental_strategy = 'merge',
        incremental_predicates = [
            "DBT_INTERNAL_SOURCE.muokattu > DBT_INTERNAL_DEST.muokattu"
        ]
    )
}}

with suoritus as (
    select distinct on (resourceid) * from {{ ref('dw_sure_suoritus') }}
    {% if target.name == 'prod' and is_incremental() %}
    where dw_metadata_dw_stored_at > (coalesce(
        (
            select start_time from {{ source('ovara', 'completed_dbt_runs') }}
            where raw_table = 'sure_suoritus'
        ),
        '1900-01-01'
        )
    )
    {% endif %}
    order by resourceid asc, muokattu desc
),

final as (
    select
        resourceid,
        komo,
        myontaja,
        tila,
        valmistuminen,
        henkilooid as henkilo_oid,
        yksilollistaminen,
        suorituskieli,
        muokattu,
        poistettu,
        source,
        vahvistettu,
        arvot
    from suoritus
)

select * from final
