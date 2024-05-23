with source as (
    select * from {{ source('ovara', 'kouta_haku') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'oid'::varchar as oid,
        data ->> 'externalId'::varchar as externalId,
        data ->> 'tila'::varchar as tila,
        data -> 'nimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'nimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'nimi' ->> 'en'::varchar as nimi_en,
        data ->> 'hakutapaKoodiUri'::varchar as hakutapaKoodiUri,
        (data ->> 'hakukohteenLiittamisenTakaraja')::timestamptz as hakukohteenLiittamisenTakaraja,
        (data ->> 'hakukohteenMuokkaamisenTakaraja')::timestamptz as hakukohteenMuokkaamisenTakaraja,
        (data -> 'hakukohteenLiittajaOrganisaatiot')::jsonb as hakukohteenLiittajaOrganisaatiot,
        (data ->> 'ajastettuJulkaisu')::timestamptz as ajastettuJulkaisu,
        (data ->> 'ajastettuHaunJaHakukohteidenArkistointi')::timestamptz as ajastettuHaunJaHakukohteidenArkistointi,
        (data ->> 'ajastettuHaunJaHakukohteidenArkistointiAjettu')::timestamptz
        as ajastettuHaunJaHakukohteidenArkistointiAjettu,
        data ->> 'kohdejoukkoKoodiUri'::varchar as kohdejoukkoKoodiUri,
        data ->> 'kohdejoukonTarkenneKoodiUri'::varchar as kohdejoukonTarkenneKoodiUri,
        data ->> 'hakulomaketyyppi'::varchar as hakulomaketyyppi,
        data ->> 'hakulomakeAtaruId'::varchar as hakulomakeAtaruId,
        (data -> 'hakulomakeKuvaus')::jsonb as hakulomakeKuvaus,
        (data -> 'hakulomakeLinkki')::jsonb as hakulomakeLinkki,
        (data -> 'metadata' -> 'yhteyshenkilot')::jsonb as yhteyshenkilot,
        (data -> 'metadata' -> 'tulevaisuudenAikataulu')::jsonb as tulevaisuudenAikataulu,
        data -> 'metadata' ->> 'isMuokkaajaOphVirkailija'::varchar as isMuokkaajaOphVirkailija,
        data -> 'metadata' -> 'koulutuksenAlkamiskausi' ->> 'alkamiskausityyppi'::varchar as alkamiskausityyppi,
        (data -> 'metadata' -> 'koulutuksenAlkamiskausi' -> 'henkilokohtaisenSuunnitelmanLisatiedot')::jsonb
        as henkilokohtaisenSuunnitelmanLisatiedot,
        data -> 'metadata' -> 'koulutuksenAlkamiskausi' -> 'koulutuksenAlkamiskausiKoodiUri'::varchar
        as koulutuksenAlkamiskausiKoodiUri,
        (data -> 'metadata' -> 'koulutuksenAlkamiskausi' ->> 'koulutuksenAlkamisvuosi')::int as koulutuksenAlkamisvuosi,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        (data -> 'hakuajat')::jsonb as hakuajat,
        data ->> 'muokkaaja' as muokkaaja,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        {{ muokattu_column() }},
        data -> 'enrichedData' ->> 'muokkaajanNimi' as muokkaajanNimi,
        {{ metadata_columns() }}
    from source
)

select * from final
