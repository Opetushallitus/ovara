with source as (
    select * from {{ source('ovara', 'kouta_valintaperuste') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

final as (
    select
        (data ->> 'id')::uuid as id,
        data ->> 'externalId'::varchar as externalId,
        data ->> 'tila'::varchar as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        data ->> 'koulutustyyppi'::varchar as koulutustyyppi,
        data ->> 'hakutapaKoodiUri'::varchar as hakutapaKoodiUri,
        data ->> 'kohdejoukkoKoodiUri'::varchar as kohdejoukkoKoodiUri,
        data -> 'nimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'nimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'nimi' ->> 'en'::varchar as nimi_en,
        (data ->> 'julkinen')::boolean as julkinen,
        (data -> 'valintakokeet')::jsonb as valintakokeet,
        data -> 'metadata' ->> 'tyyppi'::varchar as tyyppi,
        (data -> 'metadata' -> 'sisalto')::jsonb as sisalto,
        (data -> 'metadata' -> 'valintatavat')::jsonb as valintatavat,
        data -> 'metadata' -> 'kuvaus' ->> 'fi'::varchar as kuvaus_fi,
        data -> 'metadata' -> 'kuvaus' ->> 'sv'::varchar as kuvaus_sv,
        data -> 'metadata' -> 'kuvaus' ->> 'en'::varchar as kuvaus_en,
        (data -> 'medatata' -> 'hakukelpoisuus')::jsonb as hakukelpoisuus,
        (data -> 'medatata' -> 'lisatiedot')::jsonb as lisatiedot,
        (data -> 'medatata' -> 'valintakokeidenYleiskuvaus')::jsonb as valintakokeidenYleiskuvaus,
        data -> 'metadata' ->> 'isMuokkaajaOphVirkailija'::varchar as isMuokkaajaOphVirkailija,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        {{ muokattu_column() }},
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source
)

select * from final
