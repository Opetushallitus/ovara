with source as (
    select * from {{ source('ovara', 'ataru_hakemus') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

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
        (data -> 'keyValues' ->> 'home-town') as kotikunta,
        (data -> 'keyValues' ->> 'country-of-residence')::varchar as asuinmaa,
        case
            when data -> 'keyValues' ->> 'gender' = '' then null::int
            when lower(data -> 'keyValues' ->> 'gender') in ('mies', 'male', 'man') then 1
            when lower(data -> 'keyValues' ->> 'gender') in ('nainen', 'female', 'kvinna') then 2
            else (data -> 'keyValues' ->> 'gender')::int
        end as sukupuoli,
        (data -> 'keyValues' -> 'nationality')::jsonb as kansalaisuus,
        (lower(
            coalesce(
                (data -> 'keyValues' ->> 'sahkoisen-asioinnin-lupa'::varchar),
                (data -> 'keyValues' ->> 'paatos-opiskelijavalinnasta-sahkopostiin'::varchar)
            )
        ) = 'kyllä') as sahkoinenviestintalupa,
        (lower((data -> 'keyValues' ->> 'koulutusmarkkinointilupa'::varchar)) = 'kyllä') as koulutusmarkkinointilupa,
        (lower((data -> 'keyValues' ->> 'valintatuloksen-julkaisulupa'::varchar)) = 'kyllä')
        as valintatuloksen_julkaisulupa,
        (
            case
                when data -> 'keyValues' ->> 'asiointikieli' = '' then null
                else (data -> 'keyValues' ->> 'asiointikieli')
            end
        )::int as asiointikieli,
        data -> 'keyValues' ->> 'email'::varchar as sahkoposti,
        data -> 'keyValues' ->> 'phone'::varchar as puhelin,
        data -> 'keyValues' ->> 'secondary-completed-base-education–country'::varchar
        as pohjakoulutuksen_maa_toinen_aste,
        (data -> 'applicationPaymentState')::jsonb as hakemusmaksut,
        (data ->> 'modified_time')::timestamptz as muokattu,
        {{ metadata_columns() }}

    from source
)

select
    {{ dbt_utils.generate_surrogate_key(
        ['oid',
        'versio_id']
    ) }} as hakemus_versio_id,
    *
from final
