{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['valintakoe_hakemus_id']}
    ]
    )
}}

with source as (
    select
        hakemusoid as hakemus_oid,
        muokattu,
        hakutoiveet,
        row_number() over (partition by hakemusoid order by muokattu desc) as row_nr
    from {{ ref('dw_valintalaskenta_valintakoe_osallistuminen') }}
),

hakutoive as (
    select
        hakemus_oid,
        jsonb_array_elements(hakutoiveet) as hakutoiveet,
        muokattu
    from source where row_nr = 1

),

vaiheet as (
    select
        hakemus_oid,
        hakutoiveet ->> 'hakukohdeOid' as hakukohde_oid,
        jsonb_array_elements(hakutoiveet -> 'valinnanVaiheet') as vaiheet,
        muokattu
    from hakutoive
),

kokeet as (
    select
        hakemus_oid,
        hakukohde_oid,
        vaiheet ->> 'valinnanVaiheJarjestysluku' as valinnanvaihe_jarjestysluku,
        jsonb_array_elements(vaiheet -> 'valintakokeet') as kokeet,
        muokattu
    from vaiheet
),

final as (
    select
        hakemus_oid,
        hakukohde_oid,
        valinnanvaihe_jarjestysluku,
        (kokeet ->> 'aktiivinen')::boolean as aktiivinen,
        (kokeet ->> 'lahetetaankoKoekutsut')::boolean as lahetetaanko_koekutsut,
        kokeet ->> 'nimi' as nimi,
        kokeet -> 'osallistuminenTulos' -> 'kuvaus' ->> 'FI' as kuvaus_fi,
        kokeet -> 'osallistuminenTulos' -> 'kuvaus' ->> 'SV' as kuvaus_sv,
        kokeet -> 'osallistuminenTulos' -> 'kuvaus' ->> 'EN' as kuvaus_en,
        kokeet -> 'osallistuminenTulos' ->> 'laskentaTila' as laskenta_tila,
        (kokeet -> 'osallistuminenTulos' ->> 'laskentaTulos')::boolean as laskenta_tulos,
        kokeet -> 'osallistuminenTulos' ->> 'osallistuminen' as osallistuminen,
        kokeet ->> 'valintakoeOid' as valintakoe_id,
        kokeet ->> 'valintakoeTunniste' as valintakoe_tunniste,
        muokattu,
        current_timestamp as dw_metadata_int_stored_at
    from kokeet
)

select
    {{ dbt_utils.generate_surrogate_key (['hakemus_oid','hakukohde_oid','valintakoe_id']) }} as osallistuminen_id,
    {{ dbt_utils.generate_surrogate_key (['hakemus_oid','valintakoe_tunniste']) }} as valintakoe_hakemus_id,
    *
from final
