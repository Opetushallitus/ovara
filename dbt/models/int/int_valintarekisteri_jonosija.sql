{{
  config(
    materialized = 'incremental',
    unique_key='id',
    incremental_strategy='merge',
    indexes = [
        {'columns': ['id']},
        {'columns': ['dw_metadata_dw_stored_at']}
    ]
    )
}}

with raw as (
    select distinct on (id) * from {{ ref('dw_valintarekisteri_jonosija') }}
    {% if is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce((select max(t.dw_metadata_dw_stored_at) from {{ this }} as t), '1900-01-01')
    {% endif %}
    order by id asc, muokattu desc
),

final as (
    select
        {{ hakutoive_id() }},
        id,
        hakemus_oid,
        hakukohde_oid,
        valintatapajono_oid,
        hyvaksytty_harkinnanvaraisesti,
        jonosija,
        varasijan_numero,
        onko_muuttunut_viime_sijoittelussa,
        prioriteetti,
        pisteet,
        siirtynyt_toisesta_valintatapajonosta,
        sijoitteluajo_id,
        dw_metadata_dw_stored_at
    from raw
)

select * from final
