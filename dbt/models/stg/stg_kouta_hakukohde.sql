with source as (
    select * from {{ source('ovara', 'kouta_hakukohde') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        data ->> 'oid'::varchar as oid,
        data ->> 'externalId'::varchar as externalId,
        data ->> 'toteutusOid'::varchar as toteutusOid,
        data ->> 'hakuOid'::varchar as hakuOid,
        data ->> 'tila'::varchar as tila,
        coalesce((data ->> 'esikatselu')::boolean, false) as esikatselu,
        data ->> 'hakukohdeKoodiUri'::varchar as hakukohdeKoodiUri,
        data ->> 'jarjestyspaikkaOid'::varchar as jarjestyspaikkaOid,
        data ->> 'hakulomaketyyppi'::varchar as hakulomaketyyppi,
        data ->> 'hakulomakeAtaruId'::varchar as hakulomakeAtaruId,
        (data -> 'hakulomakeKuvaus')::jsonb as hakulomakeKuvaus,
        (data -> 'hakulomakeLinkki')::jsonb as hakulomakeLinkki,
        coalesce((data ->> 'kaytetaanHaunHakulomaketta')::boolean, false) as kaytetaanHaunHakulomaketta,
        (data -> 'pohjakoulutusvaatimusKoodiUrit')::jsonb as pohjakoulutusvaatimusKoodiUrit,
        (data -> 'pohjakoulutusvaatimusTarkenne')::jsonb as pohjakoulutusvaatimusTarkenne,
        (data -> 'muuPohjakoulutusvaatimus')::jsonb as muuPohjakoulutusvaatimus,
        (data ->> 'toinenAsteOnkoKaksoistutkinto')::boolean as toinenAsteOnkoKaksoistutkinto,
        (data ->> 'kaytetaanHaunAikataulua')::boolean as kaytetaanHaunAikataulua,
        data ->> 'valintaperusteId'::varchar as valintaperusteId,
        (data ->> 'liitteetOnkoSamaToimitusaika')::boolean as liitteetOnkoSamaToimitusaika,
        (data ->> 'liitteetOnkoSamaToimitusosoite')::boolean as liitteetOnkoSamaToimitusosoite,
        (data ->> 'liitteidenToimitusaika')::timestamptz as liitteidenToimitusaika,
        data ->> 'liitteidenToimitustapa'::varchar as liitteidenToimitustapa,
        (data -> 'liitteidenToimitusosoite')::jsonb as liitteidenToimitusosoite,
        (data -> 'liitteet')::jsonb as liitteet,
        (data -> 'valintakokeet')::jsonb as valintakokeet,
        (data -> 'hakuajat')::jsonb as hakuajat,
        (data -> 'metadata' -> 'valintakokeidenYleiskuvaus')::jsonb as valintakokeidenYleiskuvaus,
        (data -> 'metadata' -> 'valintaperusteenValintakokeidenLisatilaisuudet')::jsonb
        as valintaperusteenValintakokeidenLisatilaisuudet,
        (data -> 'metadata' -> 'kynnysehto')::jsonb as kynnysehto,
        (data -> 'metadata' ->> 'kaytetaanHaunAlkamiskautta')::boolean as kaytetaanHaunAlkamiskautta,
        (data -> 'metadata' -> 'koulutuksenAlkamiskausi')::jsonb as koulutuksenAlkamiskausi,
        (data -> 'metadata' -> 'aloituspaikat' ->> 'lukumaara')::int as aloituspaikat,
        (data -> 'metadata' -> 'aloituspaikat' ->> 'ensikertalaisille')::int as aloituspaikat_ensikertalaisille,
        (data -> 'metadata' -> 'aloituspaikat' -> 'kuvaus')::jsonb as aloituspaikat_kuvaus,
        (data -> 'metadata' -> 'hakukohteenLinja')::jsonb as hakukohteenLinja,
        (data -> 'metadata' -> 'painotetutArvosanat')::jsonb as painotetutArvosanat,
        (data -> 'metadata' -> 'uudenOpiskelijanUrl')::jsonb as uudenOpiskelijanUrl,
        (data -> 'metadata' ->> 'isMuokkaajaOphVirkailija')::boolean as isMuokkaajaOphVirkailija,
        (data -> 'metadata' ->> 'jarjestaaUrheilijanAmmKoulutusta')::boolean as jarjestaaUrheilijanAmmKoulutusta,
        data ->> 'muokkaaja'::varchar as muokkaaja,
        data ->> 'organisaatioOid'::varchar as organisaatioOid,
        (data -> 'kielivalinta')::jsonb as kielivalinta,
        {{ muokattu_column() }},
        data -> 'enrichedData' -> 'esitysnimi' ->> 'fi'::varchar as nimi_fi,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'sv'::varchar as nimi_sv,
        data -> 'enrichedData' -> 'esitysnimi' ->> 'en'::varchar as nimi_en,
        data -> 'enrichedData' ->> 'muokkaajanNimi'::varchar as muokkaajanNimi,
        {{ metadata_columns() }}
    from source
)

select * from final
