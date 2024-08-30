with raw as (
    select
        *,
        row_number() over (partition by oid order by muokattu desc) as row_nr
    from {{ ref('dw_kouta_hakukohde') }}
),

data as (
    select
        *,
        coalesce(nimi_fi, coalesce(nimi_en, nimi_sv)) as nimi_fi_new,
        coalesce(nimi_sv, coalesce(nimi_fi, nimi_en)) as nimi_sv_new,
        coalesce(nimi_en, coalesce(nimi_fi, nimi_sv)) as nimi_en_new
    from raw
    where row_nr = 1
),

pohjakoulutusrivit as (
    select
        oid,
        split_part(
            split_part(
                jsonb_array_elements_text(pohjakoulutusvaatimuskoodiurit), '_', 2
            ), '#', 1
        ) as pohjakoulutuskoodi
    from {{ ref('dw_kouta_hakukohde') }}
),

pohjakoulutus as (
    select
        oid as poko_oid,
        jsonb_agg(pohjakoulutuskoodi) as pohjakoulutuskoodit
    from pohjakoulutusrivit
    group by oid
),

final as (
    select
        data.hakuoid as haku_oid,
        data.toteutusoid as toteutus_oid,
        data.nimi_fi_new as nimi_fi,
        data.nimi_sv_new as nimi_sv,
        data.nimi_en_new as nimi_en,
        data.jarjestyspaikkaoid as jarjestyspaikka_oid,
        jsonb_array_length(data.valintakokeet) > 0 as on_valintakoe,
        poko.pohjakoulutuskoodit,
        {{ dbt_utils.star(from=ref('dw_kouta_hakukohde'),
            except=['nimi_fi','nimi_sv','nimi_en','toteutusoid','hakuoid','jarjestyspaikkaoid']) }}
    from data
    left join pohjakoulutus as poko on data.oid = poko.poko_oid
)

select * from final
