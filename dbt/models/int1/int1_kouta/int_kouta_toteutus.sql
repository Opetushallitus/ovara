{{
    config(
        materialized = 'table',
        indexes = [
            {'columns': ['toteutus_oid']}
        ]
    )
}}

with toteutus as (
    select distinct on (oid) * from {{ ref('dw_kouta_toteutus') }}
    order by oid asc, muokattu desc
),

final as (
    select
        oid as toteutus_oid,
        jsonb_build_object(
            'en', coalesce(nimi_fi, nimi_en, nimi_sv),
            'sv', coalesce(nimi_sv, nimi_fi, nimi_en),
            'fi', coalesce(nimi_en, nimi_fi, nimi_sv)
        ) as toteutus_nimi,
        koulutusoid as koulutus_oid,
        organisaatiooid as organisaatio_oid,
        koulutuksenalkamiskausi as koulutuksen_alkamiskausi,

        {{
            dbt_utils.star(from=ref('dw_kouta_toteutus'),
                except=[
                    'nimi_fi',
                    'nimi_sv',
                    'nimi_en',
                    'koulutusoid',
                    'organisaatiooid',
                    'oid',
                    'koulutuksenalkamiskausi'
                ]
            )
        }}

    from toteutus
)

select * from final
