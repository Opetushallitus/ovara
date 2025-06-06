{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'valintatapajono_oid',
        indexes = [
        {'columns': ['valintatapajono_oid']}
        ],
    incremental_predicates = [
        "DBT_INTERNAL_SOURCE.muokattu > DBT_INTERNAL_DEST.muokattu"
        ]
    )
}}

with jonot as (
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
    select sija.* from {{ ref('stg_valintarekisteri_jonosija') }} as sija
    {% if is_incremental() %}
        inner join jonot as jnot on sija.valintatapajono_oid = jnot.valintatapajono_oid
        where
            sija.dw_metadata_stg_stored_at > coalesce(
                (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t), '1900-01-01'
            )
    {% endif %}
),

viimeisin_sijoitteluajo as (
    select distinct on (valintatapajono_oid)
        valintatapajono_oid,
        sijoitteluajo_id,
        muokattu
    from jonosija
    order by valintatapajono_oid asc, muokattu desc
),

final as (
    select josi.*
    from jonosija as josi
    inner join viimeisin_sijoitteluajo as visi
        on
            josi.valintatapajono_oid = visi.valintatapajono_oid
            and josi.sijoitteluajo_id = visi.sijoitteluajo_id
)

select
    *,
    current_timestamp as dw_metadata_dw_stored_at
from final
