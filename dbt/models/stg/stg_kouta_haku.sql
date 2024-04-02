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
        data -> 'hakukohteenLiittajaOrganisaatiot' as hakukohteenLiittajaOrganisaatiot,
        (data ->> 'ajastettuHaunJaHakukohteidenArkistointiAjettu')::timestamptz as ajastettuHaunJaHakukohteidenArkistointiAjettu,
        data ->> 'kohdejoukkoKoodiUri'::varchar as kohdejoukkoKoodiUri,
        data ->> 'hakulomaketyyppi'::varchar as hakulomaketyyppi,
        data -> 'hakulomakeKuvaus' as hakulomakeKuvaus,
        data -> 'hakulomakeLinkki' as hakulomakeLinkki,
        data -> 'metadata' as metadata,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data -> 'hakuajat' as hakuajat,
        data ->> 'muokkaaja' as muokkaaja,
        data -> 'kielivalinta' as kielivalinta,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' ->> 'muokkaajanNimi' as muokkaajanNimi,

        {{ metadata_columns() }}

        from source

)

select * from final