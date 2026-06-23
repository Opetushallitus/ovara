{{
    config(
        materialized = 'incremental',
        unique_key = 'hakemus_oid',
        incremental_strategy = 'delete+insert',
        indexes = [
        {"columns": ["dw_metadata_dw_stored_at"]},
        {"columns": ["hakemus_oid"]}
            ],
        post_hook = [
            """delete from {{ this }} a
            where exists (
            select 1
            from {{ ref('int_ataru_hakemus') }} b
            where b.hakemus_oid = a.hakemus_oid and b.tila <> 'active'
            );"""
        ]
    )
}}

with raw as  (
    select * from {{ ref('dw_supa_harkinnanvaraisuus') }}
    {% if is_incremental() %}
    where dw_metadata_dw_stored_at >= (
        select coalesce (
            max(dw_metadata_dw_stored_at),
            '1900-01-01'
        )
        from {{ this }}
    )
    {% endif %}
),

int as (
    select
        hakemus_oid,
        rows.value ->> 'hakukohdeOid' as hakukohde_oid,
        rows.value ->> 'harkinnanvaraisuudenSyy' as harkinnanvaraisuus_syy,
        (rows.value ->> 'yliajettu')::bool as harkinnanvaraisuus_yliajettu,
        dw_metadata_source_timestamp_at,
        dw_metadata_stg_stored_at,
        dw_metadata_dbt_copied_at,
        dw_metadata_filename,
        dw_metadata_file_row_number,
        dw_metadata_dw_stored_at
    from raw hark
    cross join lateral json_array_elements(
        hark."data" -> 'harkinnanvaraisuudet'
    ) as rows (value)
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
                ['hakemus_oid',
                'hakukohde_oid']
            ) }} as hakutoive_id,
        *
        from int
)

select * from final
