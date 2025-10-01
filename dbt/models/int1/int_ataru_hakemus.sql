{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        on_schema_change= 'append_new_columns',
        unique_key = 'hakemus_oid',
        indexes = [
            {'columns' :['tiedot'], 'type': 'gin'}
        ],
        post_hook = [
            "create index if not exists ataru_hakemus_tiedot on {{ this}} ((tiedot->>'higher-completed-base-education'))",
            "create index if not exists ix_dw_metadata_dbt_copied_at on {{ this }} (dw_metadata_dbt_copied_at desc)"
        ]
    )
}}

with raw as not materialized (
    select distinct on (oid) * from {{ ref('dw_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(t.dw_metadata_dbt_copied_at) from {{ this }} as t)
    {% endif %}
    order by oid asc, versio_id desc, muokattu desc

),

final as (
    select
        oid as hakemus_oid,
        {{ dbt_utils.star(from=ref('dw_ataru_hakemus'),except = ['oid']) }},
        case
            when tila = 'inactivated'
                then true::boolean
            else false::boolean
        end as poistettu,
        hakemusmaksut ->> 'state' as hakemusmaksun_tila
    from raw
    where henkilo_oid is not null
)

select * from final
