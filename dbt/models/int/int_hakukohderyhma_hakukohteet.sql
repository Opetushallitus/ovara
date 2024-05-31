{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohderyhma_oid']}
    ]
    )
}}

with source as (
    select
        oid as hakukohderyhma_oid,
        hakukohde_oid,
        dw_metadata_source_timestamp_at as ladattu
    from {{ ref('dw_hakukohderyhmapalvelu_ryhma') }}
),

raw as (
    select
        hakukohderyhma_oid,
        jsonb_array_elements_text(hakukohde_oid) as hakukohde_oid,
        ladattu
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['hakukohderyhma_oid', 'hakukohde_oid']) }} as hakukohderyhma_id,
        hakukohderyhma_oid,
        hakukohde_oid,
        ladattu
    from raw
)

select * from final
