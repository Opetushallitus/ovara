{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['koulutus_oid']},
            {'columns':['organisaatio_oid']},
        ]
    )
}}

with toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

kausi_koodi as (
    select * from {{ ref('pub_dim_koodisto_kausi') }}
),

int as (
    select
        tote.toteutus_oid,
        tote.toteutus_nimi,
        tote.tunniste as ulkoinen_tunniste,
        tote.tila,
        tote.organisaatio_oid,
        tote.koulutus_oid,
        tote.koulutuksenalkamiskausikoodiuri,
        kaus.koodiarvo as kausi_koodi,
        kaus.koodinimi as kausi_nimi,
        coalesce(tote.koulutuksen_alkamisvuosi, date_part('year', tote.koulutuksenalkamispaivamaara))::int
        as koulutuksen_alkamisvuosi,
        tote.alkamiskausityyppi as koulutuksen_alkamiskausityyppi,
        tote.suunniteltukestovuodet,
        tote.suunniteltukestokuukaudet
    from toteutus as tote
    left join kausi_koodi as kaus on tote.koulutuksenalkamiskausikoodiuri = kaus.versioitu_koodiuri
)

select * from int
