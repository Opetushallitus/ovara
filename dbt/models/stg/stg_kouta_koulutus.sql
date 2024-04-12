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
        data ->> 'externalId'::varchar as externalId,
        (data ->> 'johtaaTutkintoon')::boolean as johtaaTutkintoon,
        data ->> 'koulutustyyppi'::varchar as koulutustyyppi,
        (data -> 'koulutuksetKoodiUri')::jsonb as koulutuksetKoodiUri,
        data ->> 'tila'::varchar as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        (data -> 'tarjoajat')::jsonb as tarjoajat,
        (data ->> 'julkinen')::boolean as julkinen,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        data ->> 'sorakuvausId'::varchar as sorakuvausId,
        data -> 'metadata' ->> 'tyyppi'::varchar as tyyppi,
        (data -> 'medadata' -> 'kuvaus')::jsonb as kuvaus,
        (data -> 'metadata' -> 'lisatiedot')::jsonb as lisatiedot,
        (data -> 'metadata' -> 'tutkinnonOsat')::jsonb as tutkinnonOsat,
        (data -> 'metadata' -> 'koulutusalaKoodiUrit')::jsonb as koulutusalaKoodiUrit,
        (data -> 'metadata' -> 'tutkintonimikeKoodiUrit')::jsonb as tutkintonimikeKoodiUrit,
        data -> 'metadata' ->> 'opintojenLaajuusyksikkoKoodiUri'::varchar as opintojenLaajuusyksikkoKoodiUri,
        (data -> 'metadata' ->> 'opintojenLaajuusNumero')::float as opintojenLaajuusNumero,
        (data -> 'metadata' ->> 'opintojenLaajuusNumeroMin')::float as opintojenLaajuusNumeroMin,
        (data -> 'metadata' ->> 'opintojenLaajuusNumeroMax')::float as opintojenLaajuusNumeroMax,
        (data -> 'metadata' ->> 'isAvoinKorkeakoulutus')::boolean as isAvoinKorkeakoulutus,
        data -> 'metadata' ->> 'tunniste'::varchar as tunniste,
        data -> 'metadata' ->> 'opinnonTyyppiKoodiUri'::varchar as opinnonTyyppiKoodiUri,
        (data -> 'metadata' -> 'korkeakoulutustyypit')::jsonb as korkeakoulutustyypit,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        data -> 'metadata' ->> 'osaamisalaKoodiUri'::varchar as osaamisalaKoodiUri,
        data -> 'metadata' ->> 'erikoistumiskoulutusKoodiUri'::varchar as erikoistumiskoulutusKoodiUri,
        (data -> 'metadata' -> 'linkkiEPerusteisiin')::jsonb,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data ->> 'teemakuva'::varchar as teemakuva,
        (data ->> 'ePerusteId')::int as ePerusteId,
        {{muokattu_column()}},
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final