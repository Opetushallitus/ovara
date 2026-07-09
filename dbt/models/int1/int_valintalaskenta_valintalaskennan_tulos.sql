{{
  config(
    materialized = 'incremental',
    unique_key = 'valinnanvaihe_id',
    incremental_strategy = 'delete+insert'
    )
}}

with source as (
    select * from {{ ref('dw_valintalaskenta_valintalaskennan_tulos') }}
    {% if is_incremental() %}
     where dw_metadata_dw_stored_at > coalesce((select max(dw_metadata_dw_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
),

final as (
    select
        valinnanvaihe_id,
        muokattu,
        data ->> 'hakuOid' as haku_oid,
        data ->> 'nimi' as nimi,
        data ->> 'hakukohdeOid' as hakukohde_oid,
        data -> 'valintatapajonot' as valintatapajonot,
        (data ->> 'createdAt')::timestamptz as luotu,
        dw_metadata_source_timestamp_at,
        dw_metadata_stg_stored_at,
        dw_metadata_dbt_copied_at,
        dw_metadata_filename,
        dw_metadata_file_row_number,
        dw_metadata_dw_stored_at
    from source
)

select * from final
