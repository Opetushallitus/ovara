{{
  config(
    materialized = 'incremental',
    unique_key = 'valintatapajono_oid',
    incremental_strategy = 'merge'
    )
}}

with jonosija as (
    select * from {{ ref('stg_valintarekisteri_jonosija') }}
),

raw as (
    select distinct on (valintatapajono_oid)
        valintatapajono_oid,
        sijoitteluajo_id,
        muokattu,
        dw_metadata_stg_stored_at
    from jonosija
    {% if is_incremental() %}
        where
            dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t), '1900-01-01'
            )
    {% endif %}
    order by valintatapajono_oid asc, muokattu desc
)

select * from raw
