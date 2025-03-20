{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with hakukohde as (
    select distinct on (oid) * from {{ ref('dw_kouta_hakukohde') }}
    order by oid asc, muokattu desc
),

final as (
    select
        oid as hakukohde_oid,
        toteutusoid as toteutus_oid,
        hakuoid as haku_oid,
        jarjestyspaikkaoid as jarjestyspaikka_oid,
        externalid as ulkoinen_tunniste,
        jsonb_build_object(
            'en', coalesce(nimi_en, nimi_fi, nimi_sv),
            'sv', coalesce(nimi_sv, nimi_fi, nimi_en),
            'fi', coalesce(nimi_fi, nimi_sv, nimi_en)
        ) as hakukohde_nimi,
        organisaatiooid as organisaatio_oid,
        valintaperusteid as valintaperuste_id,
        {{ dbt_utils.star(
            from=ref('dw_kouta_hakukohde'),
            except=[
                'oid',
                'toteutusoid',
                'jarjestyspaikkaoid',
                'externalid',
                'nimi_fi',
                'nimi_sv',
                'nimi_en',
                'valintaperusteid']
            ) }}
    from hakukohde
)

select * from final
