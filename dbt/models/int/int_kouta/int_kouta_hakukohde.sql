with raw as (
    select
        *,
        row_number() over (partition by oid order by muokattu desc) as row_nr
    from  {{ ref('dw_kouta_hakukohde') }}
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
        hakuoid as haku_oid,
        toteutusoid as toteutus_oid,
        nimi_fi_new as nimi_fi,
        nimi_sv_new as nimi_sv,
        nimi_en_new as nimi_en,
        {{ dbt_utils.star(from=ref('dw_kouta_hakukohde'), except=['nimi_fi','nimi_sv','nimi_en','toteutusoid','hakuoid']) }}
    from int
)

select * from final