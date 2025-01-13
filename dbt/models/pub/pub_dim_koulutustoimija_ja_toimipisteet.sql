with koulutustoimija as (
    select * from {{ ref('pub_dim_koulutustoimija') }}
),

oppilaitos_with_toimipisteet as (
    select * from {{ ref('pub_dim_oppilaitos_ja_toimipisteet') }}
),

final as (
    select
        kotu.organisaatio_oid,
        kotu.organisaatio_nimi,
        kotu.organisaatiotyypit,
        kotu.oppilaitostyyppi,
        kotu.tila,
        kotu.parent_oids,
        coalesce(
            jsonb_agg(distinct opto.*) filter (
                where opto.organisaatio_oid is not null
            ),
            '[]'::jsonb
        ) as children
    from
        koulutustoimija as kotu
    left join oppilaitos_with_toimipisteet as opto
        on opto.parent_oids ? kotu.organisaatio_oid
    group by
        kotu.organisaatio_oid,
        kotu.organisaatio_nimi,
        kotu.organisaatiotyypit,
        kotu.oppilaitostyyppi,
        kotu.tila,
        kotu.parent_oids

)

select * from final
