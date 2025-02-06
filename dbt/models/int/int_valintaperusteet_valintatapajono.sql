{{
  config(
    enabled=false,
    materialized='incremental',
    unique_key ='valinnanvaihe_id',
    full_refresh = false,
    indexes = [
        {'columns': ['hakukohde_oid']}
    ]
)
}}

with raw as (
    select
        valinnanvaihe_id,
        hakukohde_oid,
        valintatapajono
        ,
        row_number() over (partition by valinnanvaihe_id order by muokattu desc) as _row_nr
    from {{ ref('dw_valintaperusteet_hakukohde') }}
    {% if is_incremental() %}
        where dw_metadata_dw_stored_at > coalesce((select max(muokattu) from {{ this }}), '1900-01-01')
    {% endif %}
),

valintatapajonoja as (
    select
        valinnanvaihe_id,
        hakukohde_oid,
        jsonb_array_elements(valintatapajono) as data
    from raw
    where _row_nr = 1
),

rivit as (
    select
        data ->> 'oid' as jono_id,
        valinnanvaihe_id,
        hakukohde_oid,
        data ->> 'nimi' as nimi,
        data ->> 'kuvaus' as kuvaus,
        (data ->> 'aloituspaikat')::int as aloituspaikat,
        data ->> 'tyyppi' as tyyppi_uri,
        (data ->> 'prioriteetti')::int as prioriteetti,
        (data ->> 'siirretaanSijoitteluun')::boolean as siirretaan_sijoitteluun,
        data ->> 'tasasijasaanto' as tasasijasaanto,
        (data ->> 'eiLasketaPaivamaaranJalkeen')::timestamptz as ei_lasketa_paivamaaran_jalkeen,
        (data ->> 'eiVarasijatayttoa')::boolean as ei_varasijatayttoa,
        (data ->> 'merkitseMyohAuto')::boolean as merkitse_myoh_auto,
        (data ->> 'poissaOlevaTaytto')::boolean as poissa_oleva_taytto,
        (data ->> 'kaikkiEhdonTayttavatHyvaksytaan')::boolean as kaikki_ehdon_tayttavat_hyvaksytaan,
        (data ->> 'kaytetaanValintalaskentaa')::boolean as kaytetaan_valintalaskentaa,
        (data ->> 'valmisSijoiteltavaksi')::boolean as valmis_sijoiteltavaksi,
        (data ->> 'valisijoittelu')::boolean as valisijoittelu,
        (data ->> 'poistetaankoHylatyt')::boolean as poistetaanko_hylatyt,
        data -> 'jarjestyskriteerit' as jarjestyskriteerit
    from valintatapajonoja
),

existing_rows as (
    {% if is_incremental() %}
        select * from {{ this }}
        where hakukohde_oid in (select hakukohde_oid from valintatapajonoja)
    {% else %}
        select
            null as jono_id,
            null as valinnanvaihe_id,
            null as hakukohde_oid,
            null as nimi,
            null as kuvaus,
            null::int as aloituspaikat,
            null as tyyppi_uri,
            null::int as prioriteetti,
            null::boolean as siirretaan_sijoitteluun,
            null as tasasijasaanto,
            null::timestamptz as ei_lasketa_paivamaaran_jalkeen,
            null::boolean as ei_varasijatayttoa,
            null::boolean as merkitse_myoh_auto,
            null::boolean as poissa_oleva_taytto,
            null::boolean as kaikki_ehdon_tayttavat_hyvaksytaan,
            null::boolean as kaytetaan_valintalaskentaa,
            null::boolean as valmis_sijoiteltavaksi,
            null::boolean as valisijoittelu,
            null::boolean as poistetaanko_hylatyt,
            null::jsonb as jarjestyskriteerit
    {% endif %}
)

select
    coalesce(uusi.jono_id, vanh.jono_id) as jono_id,
    coalesce(uusi.valinnanvaihe_id, vanh.valinnanvaihe_id) as valinnanvaihe_id,
    coalesce(uusi.hakukohde_oid, vanh.hakukohde_oid) as hakukohde_oid,
    coalesce(uusi.kuvaus, vanh.kuvaus) as kuvaus,
    coalesce(uusi.aloituspaikat, vanh.aloituspaikat) as aloituspaikat,
    coalesce(uusi.tyyppi_uri, vanh.tyyppi_uri) as tyyppi_uri,
    coalesce(uusi.prioriteetti, vanh.prioriteetti) as prioriteetti,
    coalesce(uusi.siirretaan_sijoitteluun, vanh.siirretaan_sijoitteluun) as siirretaan_sijoitteluun,
    coalesce(uusi.tasasijasaanto, vanh.tasasijasaanto) as tasasijasaanto,
    coalesce(uusi.ei_lasketa_paivamaaran_jalkeen, vanh.ei_lasketa_paivamaaran_jalkeen)
    as ei_lasketa_paivamaaran_jalkeen,
    coalesce(uusi.ei_varasijatayttoa, vanh.ei_varasijatayttoa) as ei_varasijatayttoa,
    coalesce(uusi.merkitse_myoh_auto, vanh.merkitse_myoh_auto) as merkitse_myoh_auto,
    coalesce(uusi.poissa_oleva_taytto, vanh.poissa_oleva_taytto) as poissa_oleva_taytto,
    coalesce(uusi.kaikki_ehdon_tayttavat_hyvaksytaan, vanh.kaikki_ehdon_tayttavat_hyvaksytaan)
    as kaikki_ehdon_tayttavat_hyvaksytaan,
    coalesce(uusi.kaytetaan_valintalaskentaa, vanh.kaytetaan_valintalaskentaa) as kaytetaan_valintalaskentaa,
    coalesce(uusi.valmis_sijoiteltavaksi, vanh.valmis_sijoiteltavaksi) as valmis_sijoiteltavaksi,
    coalesce(uusi.valisijoittelu, vanh.valisijoittelu) as valisijoittelu,
    coalesce(uusi.poistetaanko_hylatyt, vanh.poistetaanko_hylatyt) as poistetaanko_hylatyt,
    coalesce(uusi.jarjestyskriteerit, vanh.jarjestyskriteerit) as jarjestyskriteerit,
    case when uusi.valinnanvaihe_id is null then 1::boolean else 0::boolean end as poistettu,
    current_timestamp::timestamptz as muokattu
from
    existing_rows as vanh
full outer join rivit as uusi on vanh.hakukohde_oid = uusi.hakukohde_oid and vanh.jono_id = uusi.jono_id
where coalesce(uusi.jono_id, vanh.jono_id) is not null
