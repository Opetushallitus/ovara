with raw as (
    select
        *,
        row_number() over (partition by oid order by muokattu desc) as row_nr
    from {{ ref('dw_kouta_haku') }}
),

int as (
    select
        *,
        coalesce(nimi_fi, coalesce(nimi_sv, nimi_en)) as nimi_fi_new,
        coalesce(nimi_sv, coalesce(nimi_fi, nimi_en)) as nimi_sv_new,
        coalesce(nimi_en, coalesce(nimi_fi, nimi_sv)) as nimi_en_new
    from raw
    where row_nr = 1
),

final as (
    select
        oid as haku_oid,
        jsonb_build_object(
            'en', nimi_en_new,
            'sv', nimi_sv_new,
            'fi', nimi_fi_new
        ) as haku_nimi,
        {{ dbt_utils.star(from=ref('dw_kouta_haku'), except=['oid','nimi_fi','nimi_sv','nimi_en']) }}
    from int
)

select * from final
