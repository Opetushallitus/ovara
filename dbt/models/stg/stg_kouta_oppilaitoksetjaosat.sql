with source as (
      select * from {{ source('ovara', 'kouta_koulutus') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(
    select 
        data ->> 'oid'::varchar as oid,
        data ->> 'tila'::varchar as tila,
        data ->> 'esikatselu'::varchar as esikatselu,
        (data -> 'metadata' -> 'tietoaOpiskelusta')::jsonb as tietoaOpiskelusta,
        data -> 'metadada' -> 'wwwSivu -> nimi ' ->> 'fi'::varchar wwwSivu_nimi_fi, 
        data -> 'metadada' -> 'wwwSivu -> url ' ->> 'fi'::varchar wwwSivu_url_fi,
        data -> 'metadada' -> 'wwwSivu -> nimi ' ->> 'sv'::varchar wwwSivu_nimi_svi, 
        data -> 'metadada' -> 'wwwSivu -> url ' ->> 'sv'::varchar wwwSivu_url_sv,
        data -> 'metadada' -> 'wwwSivu -> nimi ' ->> 'en'::varchar wwwSivu_nimi_en, 
        data -> 'metadada' -> 'wwwSivu -> url ' ->> 'en'::varchar wwwSivu_url_en,
        (data -> 'metadata' -> 'esittelyvideo')::jsonb as esittelyvideo,
        (data -> 'metadata' -> 'some')::jsonb as metadata_some,
        (data -> 'metadata' -> 'hakijapalveluidenYhteystiedot')::jsonb as hakijapalveluidenYhteystiedot,
        data -> 'metadata' ->'esittely' ->> 'fi'::varchar as esittely_fi,
        data -> 'metadata' ->'esittely' ->> 'sv'::varchar as esittely_sv,
        data -> 'metadata' ->'esittely' ->> 'en'::varchar as esittely_en,
        (data -> 'metadata' ->> 'korkeakouluja')::int as korkeakouluja,
        (data -> 'metadata' ->> 'tiedekuntia')::int as tiedekuntia,
        (data -> 'metadata' ->> 'kampuksia')::int as kampuksia,
        (data -> 'metadata' ->> 'yksikoita')::int as yksikoita,
        (data -> 'metadata' ->> 'toimipisteita')::int as toimipisteita,
        (data -> 'metadata' ->> 'akatemioita')::int as akatemioita,
        (data -> 'metadata' ->> 'opiskelijoita')::int as opiskelijoita,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' ->> 'jarjestaaUrheilijanAmmKoulutusta')::boolean as jarjestaaUrheilijanAmmKoulutusta,
        (data -> 'metadata' -> 'kampus')::jsonb as kampus,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'teemakuva'::varchar as teemakuva,
        data ->> 'logo'::varchar as logo,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final