with source as (
    select * from {{ source('ovara', 'kouta_toteutus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'oid' as oid,
        data ->> 'externalId' as externalId,
        data ->> 'koulutusOid' as koulutusOid,
        data ->> 'tila' as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        (data -> 'tarjoajat')::jsonb as tarjoajat,
        data -> 'metadata' ->> 'tyyppi' as tyyppi,
        data -> 'metadata' -> 'kuvaus' ->> 'fi' as kuvaus_fi,
        data -> 'metadata' -> 'kuvaus' ->> 'sv' as kuvaus_sv,
        data -> 'metadata' -> 'kuvaus' ->> 'en' as kuvaus_en,
        (data -> 'metadata' -> 'osaamisalat')::jsonb as osaamisalat,
        (data -> 'metadata' -> 'opetus' -> 'opetuskieliKoodiUrit')::jsonb as opetuskieliKoodiUrit,
        data -> 'metadata' -> 'opetus' -> 'opetuskieletKuvaus' ->> 'fi' as opetuskieletKuvaus_fi,
        data -> 'metadata' -> 'opetus' -> 'opetuskieletKuvaus' ->> 'sv' as opetuskieletKuvaus_sv,
        data -> 'metadata' -> 'opetus' -> 'opetuskieletKuvaus' ->> 'en' as opetuskieletKuvaus_en,
        (data -> 'metadata' -> 'opetus' -> 'opetusaikaKoodiUrit')::jsonb as opetusaikaKoodiUrit,
        (data -> 'metadata' -> 'opetus' -> 'opetusaikaKuvaus')::jsonb as opetusaikaKuvaus,
        (data -> 'metadata' -> 'opetus' -> 'opetustapaKoodiUrit')::jsonb as opetustapaKoodiUrit,
        (data -> 'metadata' -> 'opetus' -> 'opetustapaKuvaus')::jsonb as opetustapaKuvaus,
        (data -> 'metadata' -> 'opetus' -> 'maksut')::jsonb as maksut,
        (data -> 'metadata' -> 'opetus' -> 'maksullisuusKuvaus')::jsonb as maksullisuusKuvaus,
        (data -> 'metadata' -> 'opetus' -> 'koulutuksenAlkamiskausi')::jsonb as koulutuksenAlkamiskausi,
        (data -> 'metadata' -> 'opetus' -> 'lisatiedot')::jsonb as lisatiedot,
        (data -> 'metadata' -> 'opetus' ->> 'onkoApuraha')::boolean as onkoApuraha,
        (data -> 'metadata' -> 'opetus' ->> 'suunniteltuKestoVuodet')::int as suunniteltuKestoVuodet,
        (data -> 'metadata' -> 'opetus' ->> 'suunniteltuKestoKuukaudet')::int as suunniteltuKestoKuukaudet,
        (data -> 'metadata' -> 'opetus' -> 'suunniteltuKestoKuvaus')::jsonb as suunniteltuKestoKuvaus,
        (data -> 'metadata' -> 'asiasanat')::jsonb as asiasanat,
        (data -> 'metadata' -> 'ammattinimikkeet')::jsonb as ammattinimikkeet,
        (data -> 'metadata' -> 'yhteyshenkilot')::jsonb as yhteyshenkilot,
        (data -> 'metadata' ->> 'isHakukohteetKaytossa')::boolean as isHakukohteetKaytossa,
        data -> 'metadata' ->> 'hakutermi' as hakutermi,
        data -> 'metadata' ->> 'hakulomaketyyppi' as hakulomaketyyppi,
        (data -> 'metadata' -> 'hakulomakeLinkki')::jsonb as hakulomakeLinkki,
        (data -> 'metadata' -> 'lisatietoaHakeutumisesta')::jsonb as lisatietoaHakeutumisesta,
        (data -> 'metadata' -> 'lisatietoaValintaperusteista')::jsonb as lisatietoaValintaperusteista,
        (data -> 'metadata' -> 'hakuaika')::jsonb as hakuaika,
        (data -> 'metadata' ->> 'aloituspaikat')::int as aloituspaikat,
        (data -> 'metadata' -> 'aloituspaikkakuvaus')::jsonb as aloituspaikkakuvaus,
        (data -> 'metadata' ->> 'isAvoinKorkeakoulutus')::boolean as isAvoinKorkeakoulutus,
        data -> 'metadata' ->> 'tunniste' as tunniste,
        data -> 'metadata' ->> 'opinnonTyyppiKoodiUri' as opinnonTyyppiKoodiUri,
        (data -> 'metadata' -> 'liitetytOpintojaksot')::jsonb as liitetytOpintojaksot,
        (
            data -> 'metadata' ->> 'ammatillinenPerustutkintoErityisopetuksena'
        )::boolean as ammatillinenPerustutkintoErityisopetuksena,
        data -> 'metadata' ->> 'opintojenLaajuusyksikkoKoodiUri' as opintojenLaajuusyksikkoKoodiUri,
        (data -> 'metadata' ->> 'opintojenLaajuusNumero')::float as opintojenLaajuusNumero,
        (data -> 'metadata' ->> 'hasJotpaRahoitus')::boolean as hasJotpaRahoitus,
        (data -> 'metadata' ->> 'isTaydennyskoulutus')::boolean as isTaydennyskoulutus,
        (data -> 'metadata' ->> 'isTyovoimakoulutus')::boolean as isTyovoimakoulutus,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' -> 'kielivalikoima')::jsonb as kielivalikoima,
        (data -> 'metadata' ->> 'yleislinja')::boolean as yleislinja,
        (data -> 'metadata' -> 'painotukset')::jsonb as painotukset,
        (data -> 'metadata' -> 'erityisetKoulutustehtavat')::jsonb as erityisetKoulutustehtavat,
        (data -> 'metadata' -> 'diplomit')::jsonb as diplomit,
        (data -> 'metadata' ->> 'jarjestetaanErityisopetuksena')::boolean as jarjestetaanErityisopetuksena,
        (data -> 'metadata' -> 'taiteenalaKoodiUrit')::jsonb as taiteenalaKoodiUrit,
        (data -> 'metadata' ->> 'isPieniOsaamiskokonaisuus')::boolean as isPieniOsaamiskokonaisuus,
        data -> 'metadata' -> 'osaamistavoitteet' as osaamistavoitteet,
        data -> 'sorakuvausId' as sorakuvausId,
        data ->> 'muokkaaja' as muokkaaja,
        data ->> 'organisaatioOid' as organisaatioOid,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        (data -> 'teemakuva')::jsonb as teemakuva,
        {{ muokattu_column() }},
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi' as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv' as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en' as nimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi' as muokkaajanNimi,
        data,
        {{ metadata_columns() }}
    from source

)

select * from final
