{{
  config(
    materialized = 'incremental',
    unique_key = 'hakemus_oid',
    incremental_strategy = 'merge',
    indexes = [
        {'columns':['haku_oid']},
        {'columns':['henkilo_oid']}
    ],
    post_hook = [
            "create index if not exists ix_dw_metadata_dw_stored_at on {{ this }} (dw_metadata_dw_stored_at desc)"
    ]
    )
}}

with
{% if is_incremental() %}
    max_timestamp as materialized (
        select coalesce(
            (select max(dw_metadata_dw_stored_at) - interval '5 seconds' from {{ this }}),
            '1900-01-01'::timestamp
        ) as max_dw_metadata_dw_stored_at
    ),
{% endif %}

hakemus as (
    select
        hakemus_oid,
        versio_id,
        lomake_id,
        lomakeversio_id,
        luotu,
        tila,
        jatetty,
        kieli,
        haku_oid,
        hakukohde,
        henkilo_oid,
        hakukelpoisuus_asetettu_automaattisesti,
        etunimet,
        kutsumanimi,
        sukunimi,
        hetu,
        lahiosoite,
        postinumero,
        postitoimipaikka,
        ulk_kunta,
        kotikunta,
        asuinmaa,
        sukupuoli,
        kansalaisuus,
        sahkoinenviestintalupa,
        koulutusmarkkinointilupa,
        valintatuloksen_julkaisulupa,
        asiointikieli,
        sahkoposti,
        puhelin,
        pohjakoulutuksen_maa_toinen_aste,
        hakemusmaksut,
        muokattu,
        poistettu,
        hakemusmaksun_tila,
        kiinnostunut_oppisopimuksesta,
        pohjakoulutus_kk,
        pohjakoulutus_kk_valmistumisvuosi,
        dw_metadata_dw_stored_at
    from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        cross join max_timestamp
        where dw_metadata_dw_stored_at >= max_dw_metadata_dw_stored_at
    {% endif %}
),

kansalaisuus as (
    select
        hakemus_oid,
        jsonb_agg(kansalaisuus_puhd) as kansalaisuus
    from hakemus as hake
    cross join lateral jsonb_array_elements(hake.kansalaisuus) as kansalaisuudet
    cross join lateral jsonb_array_elements(kansalaisuudet) as kansalaisuus_puhd
    group by 1

),

final as (
    select
        hake.hakemus_oid,
        hake.versio_id,
        hake.lomake_id,
        hake.lomakeversio_id,
        hake.luotu,
        hake.tila,
        hake.jatetty,
        hake.kieli,
        hake.haku_oid,
        hake.hakukohde,
        hake.henkilo_oid,
        hake.hakukelpoisuus_asetettu_automaattisesti,
        hake.etunimet,
        hake.kutsumanimi,
        hake.sukunimi,
        hake.hetu,
        hake.lahiosoite,
        hake.postinumero,
        hake.postitoimipaikka,
        hake.ulk_kunta,
        hake.kotikunta,
        hake.asuinmaa,
        hake.sukupuoli,
        kans.kansalaisuus,
        hake.sahkoinenviestintalupa,
        hake.koulutusmarkkinointilupa,
        hake.valintatuloksen_julkaisulupa,
        hake.asiointikieli,
        hake.sahkoposti,
        hake.puhelin,
        hake.pohjakoulutuksen_maa_toinen_aste,
        hake.hakemusmaksut,
        hake.muokattu,
        hake.poistettu,
        hake.hakemusmaksun_tila,
        hake.kiinnostunut_oppisopimuksesta,
        hake.pohjakoulutus_kk,
        hake.pohjakoulutus_kk_valmistumisvuosi,
        hake.dw_metadata_dw_stored_at
    from hakemus as hake
    join kansalaisuus as kans on hake.hakemus_oid = kans.hakemus_oid
)

select * from final
