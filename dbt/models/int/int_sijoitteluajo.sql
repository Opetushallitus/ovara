{{
  config(
    materialized = 'incremental',
    unique_key = 'valintatapajono_oid',
    incremental_strategy = 'merge'
    )
}}

with jonosija as (
    select distinct on (valintatapajono_oid)
        valintatapajono_oid,
        sijoitteluajo_id,
        muokattu,
        dw_metadata_stg_stored_at
    from {{ ref('stg_valintarekisteri_jonosija') }}
    {% if is_incremental() %}
        where
            dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t), '1900-01-01'
            )
    {% endif %}
    order by valintatapajono_oid asc, muokattu desc
),

uudet as (
    select
        josi.*
    from jonosija as josi
    left join {{ this }} as vanh
        on josi.valintatapajono_oid = vanh.valintatapajono_oid
    where josi.muokattu > vanh.muokattu or vanh.muokattu is null

)

select * from uudet
