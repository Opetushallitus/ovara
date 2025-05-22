{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['organisaatio_oid']},
        {'columns': ['tila']}
    ]
    )
}}

with organisaatio as (
    select distinct on (organisaatio_oid) * from {{ ref('int_organisaatio_organisaatio') }}
    order by organisaatio_oid asc, muokattu desc
),

ylempi_toimipiste as (
    select
        organisaatio_oid,
        nimi_fi,
        nimi_sv
    from organisaatio
    where organisaatiotyypit @> '["organisaatiotyyppi_03"]'
),

kunta as (
    select * from {{ ref('int_koodisto_kunta') }}
    where viimeisin_versio
),

maakunta as (
    select * from {{ ref('int_koodisto_maakunta') }}
    where viimeisin_versio
),

kunta_maakunta as (
    select * from {{ ref('int_koodisto_kunta_maakunta') }}
    where viimeisin_versio
),

organisaatiotyyppi as (
    select * from {{ ref('int_organisaatio_organisaatiotyyppi') }}
),

int as (
    select
        org1.organisaatio_oid,
        coalesce(org1.nimi_fi, org1.nimi_sv) as nimi_fi_new,
        coalesce(org1.nimi_sv, org1.nimi_fi) as nimi_sv_new,
        coalesce(org1.nimi_fi, org1.nimi_sv) as nimi_en_new,
        coalesce(ylto.nimi_fi, ylto.nimi_sv) as nimi_fi_new_ylempi,
        coalesce(ylto.nimi_sv, ylto.nimi_fi) as nimi_sv_new_ylempi,
        coalesce(ylto.nimi_fi, ylto.nimi_sv) as nimi_en_new_ylempi,
        org1.ylempi_organisaatio,
        org1.sijaintikunta,
        org1.tila,
        org1.opetuskielet,
        org1.organisaatiotyypit,
        org1.oppilaitostyyppi,
        org1.oppilaitosnumero,
        org1.alkupvm,
        org1.lakkautuspvm
    from organisaatio as org1
    left join ylempi_toimipiste as ylto on org1.ylempi_organisaatio = ylto.organisaatio_oid
),

final as (
    select
        raw1.organisaatio_oid,
        case
            when nimi_fi_new_ylempi is not null
                then
                    jsonb_build_object(
                        'en', nimi_en_new_ylempi || ', ' || nimi_en_new,
                        'sv', nimi_sv_new_ylempi || ', ' || nimi_sv_new,
                        'fi', nimi_fi_new_ylempi || ', ' || nimi_fi_new
                    )
            else
                jsonb_build_object(
                    'en', nimi_en_new,
                    'sv', nimi_sv_new,
                    'fi', nimi_fi_new
                )
        end as organisaatio_nimi,
        raw1.ylempi_organisaatio,
        raw1.sijaintikunta,
        kunt.koodinimi as sijaintikunta_nimi,
        maak.koodiuri as sijaintimaakunta,
        maak.koodinimi as sijaintimaakunta_nimi,
        raw1.opetuskielet,
        orgt.organisaatiotyypit,
        raw1.tila,
        raw1.oppilaitostyyppi,
        raw1.oppilaitosnumero,
        raw1.alkupvm,
        raw1.lakkautuspvm
    from int as raw1
    left join kunta as kunt on raw1.sijaintikunta = kunt.koodiuri
    left join organisaatiotyyppi as orgt on raw1.organisaatio_oid = orgt.organisaatio_oid
    left join kunta_maakunta as kuma on raw1.sijaintikunta = kuma.kunta_koodiuri
    left join maakunta as maak on kuma.maakunta_koodiuri = maak.koodiuri
)

select * from final
