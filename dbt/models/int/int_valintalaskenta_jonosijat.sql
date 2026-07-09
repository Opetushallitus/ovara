with valintatapajonot as (
    select
        valintatapajono_oid,
        valinnanvaihe_id,
        valintatapajono_nimi,
        valintatapajonot,
        hakukohde_oid
    from {{ ref('int_valintalaskenta_valintatapajonot') }}
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
    (josi.obj -> 'jarjestyskriteerit')::jsonb as jarjestyskriteerit

from valintatapajonot as vajo
cross join lateral (select jsonb_array_elements(valintatapajonot->'jonosijat')) as josi(obj)