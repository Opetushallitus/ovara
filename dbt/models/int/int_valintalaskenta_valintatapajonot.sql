{{
  config(
    materialized = 'incremental',
    unique_key = 'valinnanvaihe_id',
    incremental_strategy = 'delete+insert',
    indexes = [
        {'columns': ['dw_metadata_dw_stored_at']},
        {'columns': ['valinnanvaihe_id']},
    ]
    )
}}

with tulos as (
    select * from {{ ref('int_valintalaskenta_valintalaskennan_tulos') }}
    {% if is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce((select max(dw_metadata_dw_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
),

final as (
    select
        a.valinnanvaihe_id,
        vajo.obj ->> 'nimi' as valintatapajono_nimi,
        vajo.obj ->> 'aktiivinen' as aktiivinen,
        (vajo.obj ->> 'lastModified')::date as muokattu,
        vajo.obj ->> 'prioriteetti' as prioriteetti,
        vajo.obj ->> 'aloituspaikat' as aloituspaikat,
        vajo.obj ->> 'tasasijasaanto' as tasasijasaanto,
        vajo.obj ->> 'eiVarasijatayttoa' as ei_varasijatayottoa,
        vajo.obj ->> 'valintatapajonooid' as valintatapajono_oid,
        vajo.obj ->> 'valmisSijoiteltavaksi' as valmis_sijoiteltavaksi,
        vajo.obj ->> 'siirretaanSijoitteluun' as siirretaan_sijoitteluun,
        vajo.obj ->> 'kaytetaanValintalaskentaa' as kaytetaan_valintalaskentaa,
        vajo.obj ->> 'kaikkiEhdonTayttavatHyvaksytaan' as kaikki_ehdon_tayttavat_hyvaksytaan,
        vajo.obj::jsonb as valintatapajonot,
        dw_metadata_dw_stored_at
    from tulos a
    cross join lateral (select json_array_elements(valintatapajonot) ) as vajo(obj)

)

select * from final
{% if target.name != 'prod' %}
limit 100
{% endif %}
