{{
  config(
    materialized = 'table',
    post_hook = [
        " {{ create_pk('hakukohde_oid') }}"
    ]
    )
}}

{% if execute %}

    {% set parameter_query %}
        select value::boolean
        from raw.parameters
        where parameter = 'yos_pvm_rajaus'
    {% endset %}

    {% set parameter_result = run_query(parameter_query) %}
    {% set add_yos_pvm_rajaus = parameter_result.rows[0][0] %}

{% endif %}


with hakukohde as (
    select
        hakukohde_oid,
        toteutus_oid,
        haku_oid,
        jarjestyspaikka_oid
    from {{ ref('int_hakukohde') }}
),

hakukohde_nimet as (
    select
        oppilaitos,
        jarjestyspaikka_oid
    from {{ ref('int_organisaatio_hakukohteiden_nimet') }}
),

toteutus as (
    select
        toteutus_oid,
        koulutus_oid
    from {{ ref('int_kouta_toteutus') }}
),

koulutus as (
    select
        koulutus_oid,
        koulutuksetkoodiuri,
        johtaatutkintoon
    from {{ ref('int_koulutus') }}
),

haku as (
    select
        haku.haku_oid,
        haku.kohdejoukkokoodiuri,
        haku.kohdejoukontarkennekoodiuri,
        min(haaj.obj ->> 'alkaa')::timestamptz as haku_alkaa
    from {{ ref('int_haku') }} as haku
    cross join lateral (select jsonb_array_elements(hakuajat)) as haaj (obj)
    group by 1, 2, 3
),

alat_ja_asteet as (
    select
        versioitu_koodiuri,
        kansallinenkoulutusluokitus2016koulutusastetaso2
    from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
),

yos as (
    select organisaatio_oid from {{ ref('int_yos_poikkeukset') }}
),

koulutusaste as (
    select
        koul.koulutus_oid,
        jsonb_agg(distinct alas.kansallinenkoulutusluokitus2016koulutusastetaso2) as koulutusasteet
    from koulutus as koul
    cross join lateral jsonb_array_elements_text(koul.koulutuksetkoodiuri) as j (koodi)
    inner join alat_ja_asteet as alas on j.koodi = alas.versioitu_koodiuri
    group by 1
),

koulutuksen_alkaminen as (
    select
        hakukohde_oid,
        koulutus_alkaa
    from {{ ref('int_hakukohde_paatelty_koulutuksen_alkaminen') }}
),

rows as (
    select
        hako.hakukohde_oid,
        hako.jarjestyspaikka_oid,
        haku.kohdejoukkokoodiuri,
        haku.kohdejoukontarkennekoodiuri,
        koul.johtaatutkintoon,
        koas.koulutusasteet,
        haku.haku_alkaa,
        koal.koulutus_alkaa
    from hakukohde as hako
    inner join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
    inner join koulutus as koul on tote.koulutus_oid = koul.koulutus_oid
    inner join haku on hako.haku_oid = haku.haku_oid
    inner join koulutusaste as koas on koul.koulutus_oid = koas.koulutus_oid
    left join koulutuksen_alkaminen as koal on hako.hakukohde_oid = koal.hakukohde_oid
),

ei_yos_hakukohteet as materialized (
    select hani.jarjestyspaikka_oid
    from hakukohde_nimet as hani
    inner join yos as yos1 on hani.oppilaitos = yos1.organisaatio_oid
),

final as (
    select
        hakukohde_oid,
        koulutusasteet,
        koulutusasteet ?| array['62', '63', '71', '72']
        and johtaatutkintoon
        and coalesce(
            kohdejoukontarkennekoodiuri not in (
                'haunkohdejoukontarkenne_010#1',
                'haunkohdejoukontarkenne_3#1',
                'haunkohdejoukontarkenne_11#1'
            ),
            true
        )
        and coalesce(kohdejoukkokoodiuri = 'haunkohdejoukko_12#1', false)
        {%- if add_yos_pvm_rajaus %}
            and coalesce(haku_alkaa >= '2026-08-01'::timestamptz, false)
            and coalesce(koulutus_alkaa >= '2027-01-01'::timestamptz, false)
        {% endif -%}
        and not exists (
            select 1 from ei_yos_hakukohteet as e
            where e.jarjestyspaikka_oid = rows.jarjestyspaikka_oid)
            as yos
    from rows
)

select * from final
