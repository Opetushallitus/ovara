{{
  config(
    materialized = 'incremental',
    unique_key = 'henkilo_oid',
    incremental_strategy = 'delete+insert',
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['dw_metadata_stg_stored_at']}
        ]
    )
}}

with suoritukset as (
    select
		henkilo_oid,
		(data ->  'metadata' ->> 'viimeisinMuutos')::timestamptz as muokattu,
		jsonb_array_elements(data -> 'kkSuorituksetFlat') as data,
        dw_metadata_stg_stored_at
    from {{ ref('int_supa_opiskeluoikeus') }}
    where jsonb_array_length(data -> 'kkSuorituksetFlat') > 0
    {% if is_incremental() %}
    and dw_metadata_stg_stored_at > coalesce(
            (select max(dw_metadata_stg_stored_at) from {{ this }}), '1900-01-01'
        )
    {% endif %}

),

final as (
    select
        henkilo_oid,
        reco."entiteetinTyyppi" as entiteetin_tyyppi,
        meta."luontiHetki" as luonti_hetki,
        meta."paivitysHetki" as paivitys_hetki,
        meta."parserointiHetki" as parserointi_hetki,
        meta."lahdeTunniste" as lahde_tunniste,
        meta.lahdejarjestelma as lahde_jarjestelma,
        meta."lahdeVersio" as lahde_versio,
        meta."parserVersio" as parser_versio,
        reco.tunniste as tunniste,
        reco."opiskeluoikeusTunniste" as opiskeluoikeus_tunniste,
        reco."opiskeluoikeusTyyppi" as opiskeluoikeus_tyyppi,
        reco."parentTunniste" as parent_tunniste,
        reco."lapsiTunnisteet" as lapsi_tunnisteet,
        reco."juuriSuoritusPolku" as juuri_suoritus_polku,
        vtil.arvo as virta_tila_arvo,
        vtil.koodisto as virta_tila_koodisto,
        vtil.versio as virta_tila_versio,
        reco."opiskeluoikeusAlkuPvm" as opiskeluoikeus_alku_pvm,
        reco."opiskeluoikeusLoppuPvm" as opiskeluoikeus_loppu_pvm,
        reco."opiskeluoikeusKieli" as opiskeluoikeus_kieli,
        nimi.fi as nimi_fi,
        nimi.sv as nimi_sv,
        nimi.en as nimi_en,
        reco."supaTila" as supa_tila,
        reco."komoTunniste" as komo_tunniste,
        reco.myontaja as myontaja,
        reco."suoritusPvm" as suoritus_pvm,
        reco."opiskeluoikeusAvain" as opiskeluoikeus_avain,
        reco."aloitusPvm" as aloitus_pvm,
        reco."opintoPisteet" as opinto_pisteet,
        reco.opintoviikot as opintoviikot,
        reco."hyvaksilukuPvm" as hyvaksiluku_pvm,
        reco.kieli as kieli,
        reco."koulutusKoodi" as koulutus_koodi,
        reco."jarjestavaRooli" as jarjestava_rooli,
        reco."jarjestavaKoodi" as jarjestava_koodi,
        reco."jarjestavaOsuus" as jarjestava_osuus,
        reco.arvosana as arvosana,
        reco."arvosanaAsteikko" as arvosana_asteikko,
        reco.koulutusala as koulutusala,
        reco."koulutusalaKoodisto" as koulutusala_koodisto,
        reco.opinnaytetyo as opinnaytetyo,
        reco.avain as avain,
        reco."opiskeluoikeusVirtaTunniste" as opiskeluoikeus_virta_tunniste,
        dw_metadata_stg_stored_at
    from suoritukset as suor

    cross join lateral jsonb_to_record(suor.data) as reco(
        "entiteetinTyyppi" text,
        metadata jsonb,
        tunniste uuid,
        "opiskeluoikeusTunniste" uuid,
        "opiskeluoikeusTyyppi" text,
        "parentTunniste" uuid,
        "lapsiTunnisteet" jsonb,
        "juuriSuoritusPolku" jsonb,
        "opiskeluoikeusVirtaTila" jsonb,
        "opiskeluoikeusAlkuPvm" date,
        "opiskeluoikeusLoppuPvm" date,
        "opiskeluoikeusKieli" text,
        nimi jsonb,
        "supaTila" text,
        "komoTunniste" text,
        myontaja text,
        "suoritusPvm" date,
        "opiskeluoikeusAvain" text,
        "aloitusPvm" date,
        "opintoPisteet" numeric,
        opintoviikot numeric,
        "hyvaksilukuPvm" date,
        kieli text,
        "koulutusKoodi" text,
        "jarjestavaRooli" text,
        "jarjestavaKoodi" text,
        "jarjestavaOsuus" numeric,
        arvosana text,
        "arvosanaAsteikko" text,
        koulutusala int,
        "koulutusalaKoodisto" text,
        opinnaytetyo boolean,
        avain text,
        "opiskeluoikeusVirtaTunniste" text
    )

    cross join lateral jsonb_to_record(reco.metadata) as meta(
        "luontiHetki" timestamptz,
        "paivitysHetki" timestamptz,
        "parserointiHetki" timestamptz,
        "lahdeTunniste" text,
        lahdejarjestelma text,
        "lahdeVersio" text,
        "parserVersio" int
    )

    cross join lateral jsonb_to_record(reco."opiskeluoikeusVirtaTila") as vtil(
        arvo text,
        koodisto text,
        versio int
    )

    cross join lateral jsonb_to_record(reco.nimi) as nimi(
        fi text,
        sv text,
        en text
    )
)

select * from final
