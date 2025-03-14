with hakukohde as (
    select * from {{ ref('int_kouta_hakukohde') }}
),

pohjakoulutusrivit as (
    select
        hakukohde_oid,
        split_part(
            split_part(
                jsonb_array_elements_text(pohjakoulutusvaatimuskoodiurit), '_', 2
            ), '#', 1
        ) as pohjakoulutuskoodi
    from hakukohde
),

pohjakoulutus as (
    select
        hakukohde_oid,
        jsonb_agg(pohjakoulutuskoodi) as pohjakoulutuskoodit
    from pohjakoulutusrivit
    group by hakukohde_oid
),

valintaperusteiden_aloituspaikat as (
    select * from {{ ref('int_valintaperusteet_aloituspaikat') }}
),

toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

opetuskieli as (
    select
        hakukohde_oid,
        jsonb_agg(opetuskieli) as oppilaitoksen_opetuskieli
    from
        (
            select
                hako.hakukohde_oid,
                split_part(jsonb_array_elements_text(tote.opetuskielikoodiurit), '#', 1) as opetuskieli
            from hakukohde as hako
            left join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
            order by opetuskieli
        ) as kielirivit
    group by hakukohde_oid
),

final as (
    select
        hako.hakukohde_oid,
        hako.haku_oid,
        hako.toteutus_oid,
        hako.ulkoinen_tunniste,
        hako.hakukohde_nimi,
        hako.jarjestyspaikka_oid,
        hako.tila,
        jsonb_array_length(hako.valintakokeet) > 0 as on_valintakoe,
        hako.aloituspaikat_ensikertalaisille,
        hako.hakukohdekoodiuri,
        hako.kaytetaanhaunaikataulua,
        hako.hakuajat,
        hako.koulutuksenalkamiskausi as koulutuksen_alkamiskausi,
        hako.toinenasteonkokaksoistutkinto,
        hako.jarjestaaurheilijanammkoulutusta,
        hako.aloituspaikat::bigint as hakukohteen_aloituspaikat,
        poko.pohjakoulutuskoodit,
        alpa.aloituspaikat as valintaperusteiden_aloituspaikat,
        opki.oppilaitoksen_opetuskieli
    from hakukohde as hako
    left join pohjakoulutus as poko on hako.hakukohde_oid = poko.hakukohde_oid
    left join valintaperusteiden_aloituspaikat as alpa on hako.hakukohde_oid = alpa.hakukohde_oid
    left join opetuskieli as opki on hako.hakukohde_oid = opki.hakukohde_oid
)

select * from final
