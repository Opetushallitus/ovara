{{
  config(
    materialized = 'table',
    indexes = [
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

raw as (
    select
        organisaatio_oid,
        coalesce(nimi_fi, nimi_sv) as nimi_fi_new,
        coalesce(nimi_sv, nimi_fi) as nimi_sv_new,
        coalesce(nimi_fi, nimi_sv) as nimi_en_new,
        sijaintikunta,
        ylempi_organisaatio,
        opetuskielet,
        organisaatiotyypit
    from organisaatio
    where rownr = 1 and lower(tila) = 'aktiivinen'
),

final as (
    select
        raw1.organisaatio_oid,
        jsonb_build_object(
            'en', raw1.nimi_en_new,
            'sv', raw1.nimi_sv_new,
            'fi', raw1.nimi_fi_new
        ) as organisaatio_nimi,
        raw1.sijaintikunta,
        kunt.koodinimi as sijaintikunta_nimi,
        raw1.ylempi_organisaatio,
        raw1.opetuskielet,
        raw1.organisaatiotyypit
    from raw as raw1
    left join kunta as kunt on raw1.sijaintikunta = kunt.koodiuri
)

select * from final
