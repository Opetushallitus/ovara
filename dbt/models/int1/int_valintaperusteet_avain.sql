{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('hakukohde_oid') }}"
    ]
    )
}}

with source as (
    select distinct on (hakukohde_oid) *
    from {{ ref('dw_valintaperusteet_avain') }}
    order by
        hakukohde_oid asc,
        muokattu desc
),

final as (
    select
        hakukohde_oid,
        muokattu,
        data::jsonb as data,
        dw_metadata_source_timestamp_at,
        dw_metadata_stg_stored_at,
        dw_metadata_dbt_copied_at,
        dw_metadata_filename,
        dw_metadata_file_row_number,
        dw_metadata_dw_stored_at
    from source
)

select * from final

