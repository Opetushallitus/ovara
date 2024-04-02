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
        (data ->> 'johtaaTutkintoon')::boolean as johtaaTutkintoon,
        data ->> 'koulutustyyppi'::varchar as koulutustyyppi,
        data -> 'koulutuksetKoodiUri' as koulutuksetKoodiUri,
        data ->> 'tila' as tila,
        data ->> 'esikatselu' as esikatselu,
        data -> 'tarjoajat' as tarjoajat,
        data ->> 'sorakuvausId'::varchar as sorakuvausId,
        data -> 'metadata' as metadata,
        (data ->> 'julkinen')::boolean as julkinen,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data -> 'kielivalinta' as kielivalinta,
        data ->> 'teemakuva'::varchar as teemakuva,
        data ->> 'ePerusteId'::varchar as ePerusteId,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final