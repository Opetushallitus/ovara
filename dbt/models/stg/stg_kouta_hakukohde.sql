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
        data -> 'hakulomakeKuvaus' as hakulomakeKuvaus,
        data -> 'hakulomakeLinkki' as hakulomakeLinkki,
        (data ->> 'kaytetaanHaunHakulomaketta')::boolean as kaytetaanHaunHakulomaketta,
        data -> 'pohjakoulutusvaatimusKoodiUrit' as pohjakoulutusvaatimusKoodiUrit,
        data -> 'pohjakoulutusvaatimusTarkenne' as pohjakoulutusvaatimusTarkenne,
        data -> 'muuPohjakoulutusvaatimus' as muuPohjakoulutusvaatimus,
        (data ->> 'toinenAsteOnkoKaksoistutkinto')::boolean as toinenAsteOnkoKaksoistutkinto,
        (data ->> 'kaytetaanHaunAikataulua')::boolean as kaytetaanHaunAikataulua,
        (data ->> 'liitteetOnkoSamaToimitusaika')::boolean as liitteetOnkoSamaToimitusaika,
        (data ->> 'liitteetOnkoSamaToimitusosoite')::boolean as liitteetOnkoSamaToimitusosoite,
        data -> 'liitteet' as liitteet,
        data -> 'valintakokeet' as valintakokeet,
        data -> 'hakuajat' as hakuajat,
        data -> 'metadata' -> 'valintakokeidenYleiskuvaus' as valintakokeidenYleiskuvaus,
        data -> 'metadata' -> 'valintaperusteenValintakokeidenLisatilaisuudet' as valintaperusteenValintakokeidenLisatilaisuudet,
        data -> 'metadata' -> 'kynnysehto' as kynnysehto,
        (data -> 'metadata' ->> 'kaytetaanHaunAlkamiskautta')::boolean as kaytetaanHaunAlkamiskautta,
        (data -> 'metadata' -> 'aloituspaikat' ->> 'lukumaara')::int as aloituspaikat,
        data -> 'metadata' -> 'aloituspaikat' ->> 'kuvaus' as aloituspaikat_kuvaus,
        data -> 'metadata' -> 'uudenOpiskelijanUrl' as uudenOpiskelijanUrl,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' ->> 'jarjestaaUrheilijanAmmKoulutusta')::boolean as jarjestaaUrheilijanAmmKoulutusta,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        data -> 'kielivalinta' as kielivalinta,
        (data ->> 'modified')::timestamptz as muokattu,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source
)

select * from final