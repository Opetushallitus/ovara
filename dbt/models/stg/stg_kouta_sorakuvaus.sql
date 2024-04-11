with source as (
      select * from {{ source('ovara', 'kouta_sorakuvaus') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(
    select 
        (data ->> 'id')::uuid as id,
        data ->> 'externalId'::varchar as externalId,
        data ->> 'tila'::varchar as tila,
        data -> 'nimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'nimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'nimi' ->> 'en'::varchar as nimi_en,
        data ->> 'koulutustyyppi'::varchar as koulutustyyppi,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        data -> 'metadata' -> 'kuvaus' ->> 'fi'::varchar as kuvaus_fi,
        data -> 'metadata' -> 'kuvaus' ->> 'sv'::varchar as kuvaus_sv,
        data -> 'metadata' -> 'kuvaus' ->> 'en'::varchar as kuvaus_en,
        data -> 'metadata' ->> 'koulutusalaKoodiUri'::varchar as koulutusalaKoodiUri,
        (data -> 'metadata' -> 'koulutusKoodiUrit')::jsonb as koulutusKoodiUrit,
        coalesce((data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean,false) as isMuokkaajaOphVirkailija,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        {{ muokattu_column()}},
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final
