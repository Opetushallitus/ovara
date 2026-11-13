with source as (
    select distinct on (koulutus_id) * from {{ ref('dw_koutalight_koulutus') }}
    order by koulutus_id asc, muokattu desc nulls last

),

final as (
    select
        koulutus_id,
        data ->> 'externalId' as external_id,
        data ->> 'tila' as tila,
        (data -> 'nimi')::jsonb as koulutus_nimi,
        data -> 'nimi' ->> 'fi' as koulutus_nimi_fi,
        data -> 'nimi' ->> 'sv' as koulutus_nimi_sv,
        data -> 'nimi' ->> 'en' as koulutus_nimi_en,
        data ->> 'ownerOrg' as omistaja_organisaatio,
        (data ->> 'createdAt')::timestamp as luotu,
        (data -> 'metadata' -> 'kuvaus')::jsonb as kuvaus,
        data -> 'metadata' -> 'kuvaus' ->> 'fi' as kuvaus_fi,
        data -> 'metadata' -> 'kuvaus' ->> 'sv' as kuvaus_sv,
        data -> 'metadata' -> 'kuvaus' ->> 'en' as kuvaus_en,
        (data -> 'metadata' ->> 'hakuaikaAlkaa')::timestamp as hakuaika_alkaa,
        (data -> 'metadata' ->> 'hakuaikaPaattyy')::timestamp as hakuaika_paattyy,
        (data -> 'metadata' ->> 'aloituspaikatLukumaara')::int as aloituspaikat_lkm,
        (data -> 'metadata' ->> 'isTyovoimakoulutus')::boolean as is_tyovoimakoulutus,
        (data -> 'metadata' ->> 'johtaaTutkintoon')::boolean as johtaa_tutkintoon,
        (data -> 'metadata' ->> 'isMaksullinen')::boolean as is_maksullinen,
        (data -> 'metadata' -> 'hakulomakeLinkki')::jsonb as hakulomake_linkki,
        (data -> 'metadata' -> 'hakulomakeLinkki' ->> 'fi') as hakulomake_linkki_fi,
        (data -> 'metadata' -> 'hakulomakeLinkki' ->> 'sv') as hakulomake_linkki_sv,
        (data -> 'metadata' -> 'hakulomakeLinkki' ->> 'en') as hakulomake_linkki_en,
        (data -> 'metadata' -> 'maksullisuuskuvaus')::jsonb as maksullisuus_kuvaus,
        (data -> 'metadata' -> 'maksullisuuskuvaus' ->> 'fi') as maksullisuus_kuvaus_fi,
        (data -> 'metadata' -> 'maksullisuuskuvaus' ->> 'sv') as maksullisuus_kuvaus_sv,
        (data -> 'metadata' -> 'maksullisuuskuvaus' ->> 'en') as maksullisuus_kuvaus_en,
        data -> 'kielivalinta' as kielivalinta,
        data -> 'tarjoajat' as tarjoajat,
        data -> 'metadata' -> 'ammattinimikkeet' as ammattinimikkeet,
        data -> 'metadata' -> 'asiasanat' as asiasanat,
        data -> 'metadata' -> 'opetuskielet' as opetuskielet,
        data -> 'metadata' -> 'osaaminenUrit' as osaaminen_urit_json,
        muokattu,
        dw_metadata_source_timestamp_at,
        dw_metadata_stg_stored_at,
        dw_metadata_dbt_copied_at,
        dw_metadata_filename,
        dw_metadata_file_row_number,
        dw_metadata_dw_stored_at
    from source
)

select * from final
