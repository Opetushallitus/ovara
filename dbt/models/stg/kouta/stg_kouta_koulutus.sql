with source as (
    select * from {{ source('ovara', 'kouta_koulutus') }}

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
        (data ->> 'johtaaTutkintoon')::boolean as johtaaTutkintoon,
        data ->> 'koulutustyyppi' as koulutustyyppi,
        (data -> 'koulutuksetKoodiUri')::jsonb as koulutuksetKoodiUri,
        data ->> 'tila' as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        (data -> 'tarjoajat')::jsonb as tarjoajat,
        (data ->> 'julkinen')::boolean as julkinen,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        data ->> 'sorakuvausId' as sorakuvausId,
        data -> 'metadata' ->> 'tyyppi' as tyyppi,
        (data -> 'metadata' -> 'kuvaus')::jsonb as kuvaus,
        (data -> 'metadata' -> 'lisatiedot')::jsonb as lisatiedot,
        (data -> 'metadata' -> 'tutkinnonOsat')::jsonb as tutkinnonOsat,
        (data -> 'metadata' -> 'koulutusalaKoodiUrit')::jsonb as koulutusalaKoodiUrit,
        (data -> 'metadata' -> 'tutkintonimikeKoodiUrit')::jsonb as tutkintonimikeKoodiUrit,
        data -> 'metadata' ->> 'opintojenLaajuusyksikkoKoodiUri' as opintojenLaajuusyksikkoKoodiUri,
        (data -> 'metadata' ->> 'opintojenLaajuusNumero')::float as opintojenLaajuusNumero,
        (data -> 'metadata' ->> 'opintojenLaajuusNumeroMin')::float as opintojenLaajuusNumeroMin,
        (data -> 'metadata' ->> 'opintojenLaajuusNumeroMax')::float as opintojenLaajuusNumeroMax,
        (data -> 'metadata' ->> 'isAvoinKorkeakoulutus')::boolean as isAvoinKorkeakoulutus,
        data -> 'metadata' ->> 'tunniste' as tunniste,
        data -> 'metadata' ->> 'opinnonTyyppiKoodiUri' as opinnonTyyppiKoodiUri,
        (data -> 'metadata' -> 'korkeakoulutustyypit')::jsonb as korkeakoulutustyypit,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        data -> 'metadata' ->> 'osaamisalaKoodiUri' as osaamisalaKoodiUri,
        data -> 'metadata' ->> 'erikoistumiskoulutusKoodiUri' as erikoistumiskoulutusKoodiUri,
        (data -> 'metadata' -> 'linkkiEPerusteisiin')::jsonb as linkkiEPerusteisiin,
        (data -> 'metadata' -> 'luokittelutermit')::jsonb as luokittelutermit,
        (data -> 'metadata' -> 'osaamistavoitteet')::jsonb as osaamistavoitteet,
        data -> 'metadata' ->> 'osaamismerkkiKoodiUri' as osaamismerkkiKoodiUri,
        data ->> 'muokkaaja' as muokkaaja,
        data ->> 'organisaatioOid' as organisaatioOid,
        data ->> 'teemakuva' as teemakuva,
        (data ->> 'ePerusteId')::int as ePerusteId,
        {{ muokattu_column() }},
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi' as muokkaajanNimi,
        {{ metadata_columns() }}
    from source

)

select * from final
