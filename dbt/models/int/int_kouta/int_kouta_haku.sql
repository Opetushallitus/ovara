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

koulutuksen_alkamiskausi_rivit as (
    select
        oid as haku_oid,
        case
            when koulutuksenalkamiskausi ->> 'alkamiskausityyppi' = 'alkamiskausi ja -vuosi'
                then (koulutuksenalkamiskausi ->> 'koulutuksenAlkamisvuosi')::int
            when koulutuksenalkamiskausi ->> 'alkamiskausityyppi' = 'tarkka alkamisajankohta'
                then date_part('year', (koulutuksenalkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz)::int
            else -1
        end as alkamisvuosi,
        case
            when koulutuksenalkamiskausi ->> 'alkamiskausityyppi' = 'alkamiskausi ja -vuosi'
                then koulutuksenalkamiskausi ->> 'koulutuksenAlkamiskausiKoodiUri'
            when koulutuksenalkamiskausi ->> 'alkamiskausityyppi' = 'tarkka alkamisajankohta'
                then
                    case
                        when
                            date_part(
                                'month', (koulutuksenalkamiskausi ->> 'koulutuksenAlkamispaivamaara')::timestamptz
                            )::int < 8
                            then 'kausi_k#1'
                        else 'kausi_s#1'
                    end
        end as kausi
    from raw
    where koulutuksenalkamiskausi is not null
),

koulutuksen_alkamiskausi_koodit as (
    select distinct
        haku_oid,
        case
            when alkamisvuosi = -1
                then jsonb_build_object('type', 'henkkoht')
            when alkamisvuosi is null
                then '{}'
            else jsonb_build_object(
                'type', 'kausivuosi',
                'koulutuksenAlkamisvuosi', alkamisvuosi,
                'koulutuksenAlkamiskausiKoodiUri', kausi
            )
        end as koulutuksen_alkamiskausi
    from koulutuksen_alkamiskausi_rivit
),

koulutuksen_alkamiskausi as (
    select
        haku_oid,
        jsonb_agg(koulutuksen_alkamiskausi) as koulutuksen_alkamiskausi_json
    from koulutuksen_alkamiskausi_koodit
    group by haku_oid

),

final as (
    select
        inta.oid as haku_oid,
        jsonb_build_object(
            'en', inta.nimi_en_new,
            'sv', inta.nimi_sv_new,
            'fi', inta.nimi_fi_new
        ) as haku_nimi,
        inta.koulutuksenalkamiskausi as koulutuksen_alkamiskausi,
        koal.koulutuksen_alkamiskausi_json,
        {{ dbt_utils.star(from=ref('dw_kouta_haku'),
            except=['oid','nimi_fi','nimi_sv','nimi_en','koulutuksenalkamiskausi']) }},
        kojo.haun_tyyppi
    from int as inta
    left join koulutuksen_alkamiskausi as koal on inta.oid = koal.haku_oid
    left join kohdejoukot as kojo on inta.kohdejoukko = kojo.haunkohdejoukko
)

select * from final
