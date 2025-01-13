with oppilaitos as (
    select * from {{ ref('pub_dim_oppilaitos') }}
),

toimipiste_with_toimipisteet as (
    select * from {{ ref('pub_dim_toimipiste_ja_toimipisteet') }}
),

final as (
    select
        oppi.organisaatio_oid,
        oppi.organisaatio_nimi,
        oppi.organisaatiotyypit,
        oppi.oppilaitostyyppi,
        oppi.tila,
        oppi.parent_oids,
        coalesce(
            jsonb_agg(distinct topi.*) filter (
                where topi.organisaatio_oid is not null
            ),
            '[]'::jsonb
        ) as children
    from
        oppilaitos as oppi
    left join toimipiste_with_toimipisteet as topi
        on topi.parent_oids ? oppi.organisaatio_oid
    group by
        oppi.organisaatio_oid,
        oppi.organisaatio_nimi,
        oppi.organisaatiotyypit,
        oppi.oppilaitostyyppi,
        oppi.tila,
        oppi.parent_oids
)

select * from final
