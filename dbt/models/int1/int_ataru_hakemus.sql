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
        hakemusmaksut ->> 'state' as hakemusmaksun_tila,
        tiedot ->> '74fb6885-879d-4748-a2bc-aaeb32616ba1' = '0' as kiinnostunut_oppisopimuksesta,
        tiedot -> 'higher-completed-base-education' as pohjakoulutus_kk,
        jsonb_strip_nulls(
            jsonb_build_object(
                'other-eligibility-year-of-completion', tiedot ->'other-eligibility-year-of-completion'->0->>0,
                'pohjakoulutus_amp--year-of-completion', tiedot ->'pohjakoulutus_amp--year-of-completion'->0->>0,
                'pohjakoulutus_amt--year-of-completion', tiedot ->'pohjakoulutus_amt--year-of-completion'->0->>0,
                'pohjakoulutus_amv--year-of-completion', tiedot ->'pohjakoulutus_amv--year-of-completion'->0->>0,
                'pohjakoulutus_am--year-of-completion', tiedot ->'pohjakoulutus_am--year-of-completion'->0->>0,
                'pohjakoulutus_avoin--year-of-completion', tiedot ->'pohjakoulutus_avoin--year-of-completion'->0->>0,
                'pohjakoulutus_kk_ulk--year-of-completion', tiedot ->'pohjakoulutus_kk_ulk--year-of-completion'->0->>0,
                'pohjakoulutus_lk--year-of-completion', tiedot ->'pohjakoulutus_lk--year-of-completion'->0->>0,
                'pohjakoulutus_muu--year-of-completion', tiedot ->'pohjakoulutus_muu--year-of-completion'->0->>0,
                'pohjakoulutus_ulk--year-of-completion', tiedot ->'pohjakoulutus_ulk--year-of-completion'->0->>0,
                'pohjakoulutus_yo_ammatillinen--marticulation-year-of-completion', tiedot ->'pohjakoulutus_yo_ammatillinen--marticulation-year-of-completion'->0->>0,
                'pohjakoulutus_yo_kansainvalinen_suomessa--eb--year-of-completion', tiedot ->'pohjakoulutus_yo_kansainvalinen_suomessa--eb--year-of-completion'->0->>0,
                'pohjakoulutus_yo_kansainvalinen_suomessa--ib--year-of-completion', tiedot ->'pohjakoulutus_yo_kansainvalinen_suomessa--ib--year-of-completion'->0->>0,
                'pohjakoulutus_yo_kansainvalinen_suomessa--rb--year-of-completion', tiedot ->'pohjakoulutus_yo_kansainvalinen_suomessa--rb--year-of-completion'->0->>0,
                'pohjakoulutus_yo_kansainvalinen_suomessa--year-of-completion', tiedot ->'pohjakoulutus_yo_kansainvalinen_suomessa--year-of-completion'->0->>0,
                'pohjakoulutus_yo--no-year-of-completion', tiedot ->'pohjakoulutus_yo--no-year-of-completion'->0->>0,
                'pohjakoulutus_yo_ulkomainen--eb--year-of-completion', tiedot ->'pohjakoulutus_yo_ulkomainen--eb--year-of-completion'->0->>0,
                'pohjakoulutus_yo_ulkomainen--ib--year-of-completion', tiedot ->'pohjakoulutus_yo_ulkomainen--ib--year-of-completion'->0->>0,
                'pohjakoulutus_yo_ulkomainen--rb--year-of-completion', tiedot ->'pohjakoulutus_yo_ulkomainen--rb--year-of-completion'->0->>0,
                'pohjakoulutus_yo_ulkomainen--year-of-completion', tiedot ->'pohjakoulutus_yo_ulkomainen--year-of-completion'->0->>0,
                'pohjakoulutus_yo--yes-year-of-completion', tiedot ->'pohjakoulutus_yo--yes-year-of-completion'->0->>0,
                'pohjakoulutus_yo_ammatillinen--vocational-completion-year', tiedot ->'pohjakoulutus_yo_ammatillinen--vocational-completion-year'->0->>0,
                'pohjakoulutus_kk--completion-date', tiedot ->'pohjakoulutus_kk--completion-date'->0->>0
            )
        )
        as pohjakoulutus_kk_valmistusmisvuosi
    from raw
    where henkilo_oid is not null
)

select * from final
