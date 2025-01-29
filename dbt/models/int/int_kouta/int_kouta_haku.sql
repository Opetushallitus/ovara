with raw as (
    select
        *,
        row_number() over (partition by oid order by muokattu desc) as row_nr
    from {{ ref('dw_kouta_haku') }}
),

kohdejoukot as (
    select * from {{ ref('raw_haunkohdejoukko') }}
),

int as (
    select
        *,
        coalesce(nimi_fi, coalesce(nimi_sv, nimi_en)) as nimi_fi_new,
        coalesce(nimi_sv, coalesce(nimi_fi, nimi_en)) as nimi_sv_new,
        coalesce(nimi_en, coalesce(nimi_fi, nimi_sv)) as nimi_en_new,
        substring(kohdejoukkokoodiuri from '_(.+)#') as kohdejoukko
    from raw
    where row_nr = 1
),

final as (
    select
        inta.oid as haku_oid,
        jsonb_build_object(
            'en', inta.nimi_en_new,
            'sv', inta.nimi_sv_new,
            'fi', inta.nimi_fi_new
        ) as haku_nimi,
        koulutuksenalkamiskausi as koulutuksen_alkamiskausi,
        {{ dbt_utils.star(from=ref('dw_kouta_haku'), except=['oid','nimi_fi','nimi_sv','nimi_en','koulutuksenalkamiskausi']) }},
        kojo.haun_tyyppi
    from int as inta
    left join kohdejoukot as kojo on inta.kohdejoukko = kojo.haunkohdejoukko
)

select * from final
