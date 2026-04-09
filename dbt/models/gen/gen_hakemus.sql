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
            (select max(dw_metadata_dw_stored_at) from {{ this }}),
            '1900-01-01'::timestamp
        ) - interval '5 seconds' as max_dw_metadata_dw_stored_at
    ),
{% endif %}

source as (
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
)

select * from source
