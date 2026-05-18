{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'delete+insert',
        unique_key = 'hakemus_oid',
        indexes = [
        {"columns": ["hakemus_oid"]},
        {"columns": ["dw_metadata_dw_stored_at"]},
        {"columns": ["haku_oid"]}
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
    select * from {{ ref('dw_supa_ensikertalainen') }}
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
    data ->> 'henkiloOid' as henkilo_oid,
    data ->> 'hakuOid' as haku_oid,
    (data->> 'isEnsikertalainen')::bool as isensikertalainen,
    data -> 'menettamisenPeruste' ->> 'peruste' as menettamisen_peruste,
    (data -> 'menettamisenPeruste' ->> 'paivamaara')::timestamptz as menettamisen_paivamaara,
    dw_metadata_source_timestamp_at,
    dw_metadata_stg_stored_at,
    dw_metadata_dbt_copied_at,
    dw_metadata_filename,
    dw_metadata_file_row_number,
    dw_metadata_dw_stored_at
from raw
