{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'jonosija_id',
        indexes = [
        {'columns': ['jonosija_id']}
        ]
    )
}}

with source as (
    select
        jono.*
    from {{ ref('stg_valintarekisteri_jonosija') }} as jono
    inner join {{ ref('int_sijoitteluajo') }} as siaj
    on jono.valintatapajono_oid = siaj.valintatapajono_oid and jono.sijoitteluajo_id =siaj.sijoitteluajo_id
    {% if is_incremental() %}
    where jono.dw_metadata_stg_stored_at > coalesce(
        (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t),
        '1900-01-01'
        )
    {% endif %}
)

select
    *,
    current_timestamp as dw_metadata_dw_stored_at
from source
