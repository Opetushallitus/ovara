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
)

select * from source
