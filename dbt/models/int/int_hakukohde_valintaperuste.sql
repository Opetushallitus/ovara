{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid','tunniste']}
    ],
    post_hook = [
        "{{ create_pk('hakukohde_valintaperuste_id') }}"
    ]
    )
}}
with source as (
    select * from {{ ref('int_valintaperusteet_avain') }}
),

final as (
select
        hakukohde_oid,
        vapa.tunniste,
        vapa.kuvaus,
        vapa.min,
        vapa.max,
        vapa.lahde,
        vapa.funktiotyyppi,
        vapa."onPakollinen" as on_pakollinen,
        vapa.tilastoidaan,
        vapa."vaatiiOsallistumisen" as vaatii_osallistumisen,
        vapa."syotettavissaKaikille" as syotettavissa_kaikille,
        vapa."osallistuminenTunniste" as osallistuminen_tunniste,
        vapa."syötettavanArvonTyyppi" ->> 'uri' as tyyppi
    from source
    cross join lateral jsonb_to_recordset(data-> 'valintaperusteDTO') as vapa(
        tunniste text,
        kuvaus text,
        min text,
        max text,
        lahde text,
        funktiotyyppi text,
        "onPakollinen" boolean,
        "tilastoidaan" boolean,
        "vaatiiOsallistumisen" boolean,
        "syotettavissaKaikille" boolean,
        "osallistuminenTunniste" text,
        "syötettavanArvonTyyppi" jsonb
    )

)

select
     {{ dbt_utils.generate_surrogate_key(['hakukohde_oid', 'tunniste']) }} as hakukohde_valintaperuste_id,
    * from final
