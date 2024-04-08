with source as (
      select * from {{ source('ovara', 'kouta_toteutus') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(
    select 
        data ->> 'oid'::varchar as oid,
        data ->> 'koulutusOid'::varchar as koulutusOid,
        data ->> 'tila'::varchar as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        data -> 'tarjoajat' as tarjoajat,
        data -> 'metadata' ->> 'tyyppi'::varchar as tyyppi,
        data -> 'metadata' -> 'kuvaus' ->>'fi'::varchar as kuvaus_fi,
        data -> 'metadata' -> 'kuvaus' ->>'sv'::varchar as kuvaus_sv,
        data -> 'metadata' -> 'kuvaus' ->>'en'::varchar as kuvaus_en,
        data -> 'metadata' ->'osaamisalat' as osaamisalat,
        data -> 'metadata' ->'opetus' -> 'opetuskieliKoodiUrit' as opetuskieliKoodiUrit,
        data -> 'metadata' ->'opetus' -> 'opetuskieletKuvaus' ->> 'fi'::varchar as opetuskieletKuvaus_fi,
        data -> 'metadata' ->'opetus' -> 'opetuskieletKuvaus' ->> 'sv'::varchar as opetuskieletKuvaus_sv,
        data -> 'metadata' ->'opetus' -> 'opetuskieletKuvaus' ->> 'en'::varchar as opetuskieletKuvaus_en,
        data -> 'metadata' ->'opetus' -> 'opetusaikaKoodiUrit' as opetusaikaKoodiUrit,
        data -> 'metadata' ->'opetus' -> 'opetusaikaKuvaus' as opetusaikaKuvaus,
        data -> 'metadata' ->'opetus' -> 'opetustapaKoodiUrit' as opetustapaKoodiUrit,
        data -> 'metadata' ->'opetus' -> 'opetustapaKuvaus' as opetustapaKuvaus,
        data -> 'metadata' ->'opetus' ->> 'maksullisuustyyppi'::varchar as maksullisuustyyppi,
        data -> 'metadata' ->'opetus' -> 'maksullisuusKuvaus' as maksullisuusKuvaus,
        data -> 'metadata' ->'opetus' -> 'koulutuksenAlkamiskausi' ->>'alkamiskausityyppi'::varchar as alkamiskausityyppi,
        data -> 'metadata' ->'opetus' -> 'koulutuksenAlkamiskausi' -> 'henkilokohtaisenSuunnitelmanLisatiedot' as henkilokohtaisenSuunnitelmanLisatiedot,
        data -> 'metadata' ->'opetus' -> 'koulutuksenAlkamiskausi' ->> 'koulutuksenAlkamiskausiKoodiUri'::varchar as koulutuksenAlkamiskausiKoodiUri,
        (data -> 'metadata' ->'opetus' -> 'koulutuksenAlkamiskausi' ->> 'koulutuksenAlkamisvuosi')::int as koulutuksenAlkamisvuosi,
        data -> 'metadata' ->'opetus' -> 'lisatiedot' as lisatiedot,
        (data -> 'metadata' ->'opetus' ->> 'onkoApuraha')::boolean as onkoApuraha,
        (data -> 'metadata' ->'opetus' ->> 'suunniteltuKestoVuodet')::int as suunniteltuKestoVuodet,
        (data -> 'metadata' ->'opetus' ->> 'suunniteltuKestoKuukaudet')::int as suunniteltuKestoKuukaudet,
        data -> 'metadata' ->'opetus' -> 'suunniteltuKestoKuvaus' as suunniteltuKestoKuvaus,
        data -> 'metadata' ->'asiasanat' as asiasanat,
        data -> 'metadata' ->'ammattinimikkeet' as ammattinimikkeet,
        data -> 'metadata' ->'yhteyshenkilot' as yhteyshenkilot,
        (data -> 'metadata' ->> 'ammatillinenPerustutkintoErityisopetuksena')::boolean as ammatillinenPerustutkintoErityisopetuksena,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' ->> 'hasJotpaRahoitus')::boolean as hasJotpaRahoitus,
        (data -> 'metadata' ->> 'isTaydennyskoulutus')::boolean as isTaydennyskoulutus,
        (data -> 'metadata' ->> 'isTyovoimakoulutus')::boolean as isTyovoimakoulutus,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data -> 'kielivalinta' as kielivalinta,
        data -> 'teemakuva' as teemakuva,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as esitysnimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as esitysnimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as esitysnimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final
