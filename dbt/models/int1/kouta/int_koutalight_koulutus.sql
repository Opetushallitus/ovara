with source as (
    select distinct on (koulutus_id) * from {{ ref('dw_koutalight_koulutus') }}
    order by koulutus_id asc, muokattu desc

),

final as (
    select
        koulutus_id,
        data ->> 'externalId' as external_id,
        data ->> 'tila' as tila,
        data -> 'nimi' ->> 'fi' as nimi_fi,
        data -> 'nimi' ->> 'sv' as nimi_sv,
        data -> 'nimi' ->> 'en' as nimi_en,
        data -> 'nimi' as koulutus_nimi,
        data ->> 'ownerOrg' as omistaja_organisaatio,
        (data ->> 'createdAt')::timestamp as luotu,
        data -> 'metadata' -> 'kuvaus' as kuvaus,
        (data -> 'metadata' ->> 'hakuaikaAlkaa')::timestamp as hakuaika_alkaa,
        (data -> 'metadata' ->> 'hakuaikaPaattyy')::timestamp as hakuaika_paattyy,
        (data -> 'metadata' ->> 'aloituspaikatLukumaara')::int as aloituspaikat_lkm,
        (data -> 'metadata' ->> 'isTyovoimakoulutus')::boolean as is_tyovoimakoulutus,
        (data -> 'metadata' ->> 'johtaaTutkintoon')::boolean as johtaa_tutkintoon,
        (data -> 'metadata' ->> 'isMaksullinen')::boolean as is_maksullinen,
        data -> 'metadata' -> 'hakulomakeLinkki' as hakulomake_linkki,
        data -> 'metadata' -> 'maksullisuuskuvaus' as maksullisuus_kuvaus,
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
