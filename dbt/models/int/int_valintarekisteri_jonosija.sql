{{
    config(
        materialized = 'incremental',
        unique_key='id',
        incremental_strategy='append',
        indexes = [
            {'columns': ['id']},
            {'columns': ['dw_metadata_dw_stored_at']}
        ],
        pre_hook = [
            "set enable_seqscan = off",
            "
            /*
                Tämä poistaa kaikki rivit taulusta joissa valintatapajono_oid on mukana uudessa datassa.
                sen jälkeen kaikki uusi data lisätään tauluun.
                Tällä tavalla datassa on aina vaan valintatapajono_oidin viimeisimmät tulokset ilman että koko taulua tarvitsee aina päivittää
            */

            delete from {{ this }}
                where valintatapajono_oid in (
                    select distinct valintatapajono_oid
                    from {{ ref('dw_valintarekisteri_jonosija') }} where dw_metadata_dw_stored_at >
                    coalesce(
                        (select max(t.dw_metadata_dw_stored_at) from {{ this }} as t),
                        '1900-01-01'
                    )
                )"
        ],
        post_hook = [
            "set enable_seqscan = on"
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
