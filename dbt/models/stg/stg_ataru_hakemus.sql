with source as (
    select * from {{ source('ovara', 'ataru_hakemus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'hakemusOid'::varchar as oid,
        (data ->> 'id')::int as versio_id,
        (data ->> 'form_key')::uuid as lomake_id,
        (data ->> 'form')::int as lomakeversio_id,
        (data -> 'keyValues')::jsonb as tiedot,
        (data -> 'attachments')::jsonb as liitteet,
        (data ->> 'created_time')::timestamptz as luotu,
        data ->> 'state'::varchar as tila,
        (data ->> 'submitted')::timestamptz as jatetty,
        data ->> 'lang'::varchar as kieli,
        (data ->> 'application_hakukohde_reviews')::jsonb as kasittelymerkinnat,
        data ->> 'hakuOid'::varchar as haku_oid,
        (data -> 'hakukohde')::jsonb as hakukohde,
        data ->> 'person_oid'::varchar as henkilo_oid,
        (data -> 'eligibility-set-automatically')::jsonb as hakukelpoisuus_asetettu_automaattisesti,
        data -> 'keyValues' ->> 'first-name'::varchar as etunimet,
        data -> 'keyValues' ->> 'preferred-name'::varchar as kutsumanimi,
        data -> 'keyValues' ->> 'last-name'::varchar as sukunimi,
        data -> 'keyValues' ->> 'ssn'::varchar as hetu,
        data -> 'keyValues' ->> 'address'::varchar as lahiosoite,
        data -> 'keyValues' ->> 'postal-code'::varchar as postinumero,
        data -> 'keyValues' ->> 'postal-office'::varchar as postitoimipaikka,
        data -> 'keyValues' ->> 'city'::varchar as ulk_kunta,
        (data -> 'keyValues' ->> 'home-town')::int as kotikunta,
        (data -> 'keyValues' ->> 'country-of-residence')::int as asuinmaa,
        (data -> 'keyValues' ->> 'gender')::int as sukupuoli,
        (data -> 'keyValues' -> 'nationality')::jsonb as kansalaisuus,
        (lower((data -> 'keyValues' ->> 'sahkoisen-asioinnin-lupa'::varchar)) = 'kyllä') as sahkoinenviestintalupa,
        (lower((data -> 'keyValues' ->> 'koulutusmarkkinointilupa'::varchar)) = 'kyllä') as koulutusmarkkinointilupa,
        (lower((data -> 'keyValues' ->> 'valintatuloksen-julkaisulupa'::varchar)) = 'kyllä')
        as valintatuloksen_julkaisulupa,
        (data -> 'keyValues' ->> 'asiointikieli')::int as asiointikieli,
        data -> 'keyValues' ->> 'email'::varchar as sahkoposti,
        data -> 'keyValues' ->> 'phone'::varchar as puhelin,
        data -> 'keyValues' ->> 'secondary-completed-base-education–country'::varchar
        as pohjakoulutuksen_maa_toinen_aste,
        (data -> 'keyValues')::jsonb as keyvalues,
        (data ->> 'modified_time')::timestamptz as muokattu,
        {{ metadata_columns() }}

    from source
)

select * from final
