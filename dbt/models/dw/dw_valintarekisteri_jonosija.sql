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

with jonot as ( --noqa: ST03
    select distinct jono.valintatapajono_oid
    from {{ ref('stg_valintarekisteri_jonosija') }} as jono
    left join {{ ref('int_sijoitteluajo') }} as siaj on jono.valintatapajono_oid = siaj.valintatapajono_oid
    where
        jono.muokattu > siaj.muokattu
    {% if is_incremental() %}
            and jono.dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t),
                '1900-01-01'
            )
        {% endif %}
),

jonosija as (
    select distinct on (sija.jonosija_id) sija.* from {{ ref('stg_valintarekisteri_jonosija') }} as sija
    {% if is_incremental() %}
        inner join jonot as jnot on sija.valintatapajono_oid = jnot.valintatapajono_oid
        where
            sija.dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t), '1900-01-01'
            )
    {% endif %}
        order by jonosija_id asc, muokattu desc
),

viimeisin_sijoitteluajo as (
    select distinct on (jonosija_id)
        jonosija_id,
        valintatapajono_oid,
        sijoitteluajo_id,
        muokattu
    from jonosija
    order by jonosija_id asc, muokattu desc
),

final as (
    select josi.*
    from jonosija as josi
    inner join viimeisin_sijoitteluajo as visi
        on
            josi.jonosija_id = visi.jonosija_id
            and josi.sijoitteluajo_id = visi.sijoitteluajo_id
)

select
    *,
    current_timestamp as dw_metadata_dw_stored_at
from final
