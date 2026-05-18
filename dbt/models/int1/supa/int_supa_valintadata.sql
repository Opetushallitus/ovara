{{
    config(
        materialized = 'incremental',
        unique_key = 'hakemus_oid',
        incremental_strategy = 'delete+insert',
        indexes = [
        {"columns": ["dw_metadata_dw_stored_at"]},
        {"columns": ["haku_oid"]},
        {'columns': ['keyvalues'], 'type': 'gin'}
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

with final as  (
    select * from {{ ref('dw_supa_valintadata') }}
    {% if is_incremental() %}
    where dw_metadata_dw_stored_at >= (
        select coalesce (
            max(dw_metadata_dw_stored_at),
            '1900-01-01'
        )
        from {{ this }}
    )
    {% endif %}
)

select
    hakemus_oid,
    data ->> 'hakuOid' as haku_oid,
    (data -> 'avainArvot')::jsonb as keyvalues,
    dw_metadata_source_timestamp_at,
    dw_metadata_stg_stored_at,
    dw_metadata_dbt_copied_at,
    dw_metadata_filename,
    dw_metadata_file_row_number,
    dw_metadata_dw_stored_at
 from final
