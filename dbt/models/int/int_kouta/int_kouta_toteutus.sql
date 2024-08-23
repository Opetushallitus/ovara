{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['oid']}
        ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by oid order by muokattu desc) as row_nr
    from  {{ ref('dw_kouta_toteutus') }}
),

int as (
    select
    *,
    coalesce(nimi_fi,coalesce(nimi_en,nimi_sv)) as nimi_fi_new,
    coalesce(nimi_sv,coalesce(nimi_fi,nimi_en)) as nimi_sv_new,
    coalesce(nimi_en,coalesce(nimi_fi,nimi_sv)) as nimi_en_new
    from raw
    where row_nr = 1
),

final as (
    select
        nimi_fi_new as nimi_fi,
        nimi_sv_new as nimi_sv,
        nimi_en_new as nimi_en,
        koulutusoid as koulutus_oid,
        {{ dbt_utils.star(from=ref('dw_kouta_toteutus'), except=['nimi_fi','nimi_sv','nimi_en','koulutusoid']) }}

    from int
)

select * from final