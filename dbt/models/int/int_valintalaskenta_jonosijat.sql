{{
  config(
    materialized = 'incremental',
    unique_key = 'valinnanvaihe_id',
    incremental_strategy = 'delete+insert',
    indexes = [
        {'columns': ['dw_metadata_dw_stored_at']},
        {'columns': ['valinnanvaihe_id']}
    ]

    )
}}
with valintatapajonot as (
    select
        valintatapajono_oid,
        valinnanvaihe_id,
        valintatapajono_nimi,
        valintatapajonot,
        hakukohde_oid,
        dw_metadata_dw_stored_at
    from {{ ref('int_valintalaskenta_valintatapajonot') }}
    {% if is_incremental() %}
      where dw_metadata_dw_stored_at > coalesce((select max(dw_metadata_dw_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
)

select
	vajo.valintatapajono_oid,
    vajo.valinnanvaihe_id,
	vajo.valintatapajono_nimi,
    vajo.hakukohde_oid,
    josi.obj ->> 'hakemusOid' as hakemus_oid ,
    josi.obj ->> 'hakijaOid' as hakija_oid,
    (josi.obj ->> 'muokattu')::boolean as onko_muokattu,
    (josi.obj ->> 'lastModified')::date as muokattu,
    josi.obj ->> 'prioriteetti' as prioriteetti,
    josi.obj ->> 'tuloksenTila'as tuloksen_tila,
    (josi.obj ->> 'hylattyValisijoittelussa')::boolean as hylatty_valisijoittelussa,
    (josi.obj -> 'syotetytArvot')::jsonb as syotetyt_arvot,
    (josi.obj -> 'funktioTulokset')::jsonb as funktioTulokset,
    (josi.obj -> 'jarjestyskriteerit')::jsonb as jarjestyskriteerit,
    vajo.dw_metadata_dw_stored_at

from valintatapajonot as vajo
cross join lateral (select jsonb_array_elements(valintatapajonot->'jonosijat')) as josi(obj)