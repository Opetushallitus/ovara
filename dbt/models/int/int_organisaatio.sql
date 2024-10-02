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
    select
        *,
        row_number() over (partition by organisaatio_oid order by muokattu desc) as rownr
    from {{ ref('dw_organisaatio_organisaatio') }}
),

kunta as (
    select * from {{ ref('int_koodisto_kunta') }} where viimeisin_versio
),

organisaatiotyyppi as (
    select * from {{ ref('int_organisaatio_organisaatiotyyppi') }}
),

raw as (
    select
        organisaatio_oid,
        coalesce(nimi_fi, nimi_sv) as nimi_fi_new,
        coalesce(nimi_sv, nimi_fi) as nimi_sv_new,
        coalesce(nimi_fi, nimi_sv) as nimi_en_new,
        ylempi_organisaatio,
        sijaintikunta,
        tila,
        opetuskielet,
        organisaatiotyypit
    from organisaatio
    where rownr = 1
),

final as (
    select
        raw1.organisaatio_oid,
        jsonb_build_object(
            'en', raw1.nimi_en_new,
            'sv', raw1.nimi_sv_new,
            'fi', raw1.nimi_fi_new
        ) as organisaatio_nimi,
        raw1.ylempi_organisaatio,
        raw1.sijaintikunta,
        kunt.koodinimi as sijaintikunta_nimi,
        raw1.opetuskielet,
        orgt.organisaatiotyypit,
        raw1.tila
    from raw as raw1
    left join kunta as kunt on raw1.sijaintikunta = kunt.koodiuri
    left join organisaatiotyyppi as orgt on raw1.organisaatio_oid = orgt.organisaatio_oid
)

select * from final
