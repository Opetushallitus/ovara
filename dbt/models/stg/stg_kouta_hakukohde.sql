with source as (
      select * from {{ source('ovara', 'kouta_hakukohde') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(   select 
        data ->> 'oid'::varchar as oid,
        data ->> 'toteutusOid'::varchar as toteutusOid,
        data ->> 'hakuOid'::varchar as hakuOid,
        data ->> 'tila'::varchar as tila,
        (data ->> 'esikatselu')::boolean as esikatselu,
        data ->> 'jarjestyspaikkaOid'::varchar as jarjestyspaikkaOid,
        (data -> 'hakulomakeKuvaus')::jsonb as hakulomakeKuvaus,
        (data -> 'hakulomakeLinkki')::jsonb as hakulomakeLinkki,
        (data ->> 'kaytetaanHaunHakulomaketta')::boolean as kaytetaanHaunHakulomaketta,
        (data -> 'pohjakoulutusvaatimusKoodiUrit')::jsonb as pohjakoulutusvaatimusKoodiUrit,
        (data -> 'pohjakoulutusvaatimusTarkenne')::jsonb as pohjakoulutusvaatimusTarkenne,
        (data -> 'muuPohjakoulutusvaatimus')::jsonb as muuPohjakoulutusvaatimus,
        (data ->> 'toinenAsteOnkoKaksoistutkinto')::boolean as toinenAsteOnkoKaksoistutkinto,
        (data ->> 'kaytetaanHaunAikataulua')::boolean as kaytetaanHaunAikataulua,
        (data ->> 'liitteetOnkoSamaToimitusaika')::boolean as liitteetOnkoSamaToimitusaika,
        (data ->> 'liitteetOnkoSamaToimitusosoite')::boolean as liitteetOnkoSamaToimitusosoite,
        (data -> 'liitteet')::jsonb as liitteet,
        (data -> 'valintakokeet')::jsonb as valintakokeet,
        (data -> 'hakuajat')::jsonb as hakuajat,
        (data -> 'metadata' -> 'valintakokeidenYleiskuvaus')::jsonb as valintakokeidenYleiskuvaus,
        (data -> 'metadata' -> 'valintaperusteenValintakokeidenLisatilaisuudet')::jsonb as valintaperusteenValintakokeidenLisatilaisuudet,
        (data -> 'metadata' -> 'kynnysehto')::jsonb as kynnysehto,
        (data -> 'metadata' ->> 'kaytetaanHaunAlkamiskautta')::boolean as kaytetaanHaunAlkamiskautta,
        (data -> 'metadata' -> 'aloituspaikat' ->> 'lukumaara')::int as aloituspaikat,
        (data -> 'metadata' -> 'aloituspaikat' -> 'kuvaus')::jsonb as aloituspaikat_kuvaus,
        (data -> 'metadata' -> 'uudenOpiskelijanUrl')::jsonb as uudenOpiskelijanUrl,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' ->> 'jarjestaaUrheilijanAmmKoulutusta')::boolean as jarjestaaUrheilijanAmmKoulutusta,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source
)

select * from final