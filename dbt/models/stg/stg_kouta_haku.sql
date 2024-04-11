with source as (
      select * from {{ source('ovara', 'kouta_haku') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(   
    select 
        data ->> 'oid'::varchar as oid,
        data ->> 'tila'::varchar as tila,
        data -> 'nimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'nimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'nimi' ->> 'en'::varchar as nimi_en,
        data ->> 'hakutapaKoodiUri'::varchar as hakutapaKoodiUri,
        (data -> 'hakukohteenLiittajaOrganisaatiot')::jsonb as hakukohteenLiittajaOrganisaatiot,
        (data ->> 'ajastettuHaunJaHakukohteidenArkistointiAjettu')::timestamptz as ajastettuHaunJaHakukohteidenArkistointiAjettu,
        data ->> 'kohdejoukkoKoodiUri'::varchar as kohdejoukkoKoodiUri,
        data ->> 'hakulomaketyyppi'::varchar as hakulomaketyyppi,
        (data -> 'hakulomakeKuvaus')::jsonb as hakulomakeKuvaus,
        (data -> 'hakulomakeLinkki')::jsonb as hakulomakeLinkki,
        (data -> 'metadata' -> 'yhteyshenkilot')::jsonb as yhteyshenkilot,
        (data -> 'metadata' -> 'tulevaisuudenAikataulu')::jsonb as tulevaisuudenAikataulu,
        data -> 'metadata' ->> 'isMuokkaajaOphVirkailija'::varchar as isMuokkaajaOphVirkailija,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        (data -> 'hakuajat')::jsonb as hakuajat,
        data ->> 'muokkaaja' as muokkaaja,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' ->> 'muokkaajanNimi' as muokkaajanNimi,

        {{ metadata_columns() }}

        from source

)

select * from final