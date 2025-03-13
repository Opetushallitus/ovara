{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select distinct on (oid) * from {{ ref('dw_kouta_koulutus') }}
    order by oid asc, muokattu desc
),

int as (
    select
        *,
        coalesce(nimi_fi, coalesce(nimi_sv, nimi_en)) as nimi_fi_new,
        coalesce(nimi_sv, coalesce(nimi_fi, nimi_en)) as nimi_sv_new,
        coalesce(nimi_en, coalesce(nimi_fi, nimi_sv)) as nimi_en_new
    from raw
),

final as (
    select
        oid as koulutus_oid,
        jsonb_build_object(
            'en', nimi_en_new,
            'sv', nimi_sv_new,
            'fi', nimi_fi_new
        ) as koulutus_nimi,
        organisaatiooid as organisaatio_oid,
        {{ dbt_utils.star(from=ref('dw_kouta_koulutus'),
            except=['nimi_fi','nimi_sv','nimi_en','organisaatiooid','oid']) }}

    from int
)

select * from final
