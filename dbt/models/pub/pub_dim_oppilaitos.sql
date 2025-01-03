{{
  config(
    materialized = 'view',
    )
}}

with
organisaatio as (
    select * from {{ ref('pub_dim_organisaatio') }}
),

organisaatio_rakenne as (
    select * from {{ ref('pub_dim_organisaatio_rakenne') }}
),

final as (
    select
        orga.organisaatio_oid,
        orga.organisaatio_nimi,
        orga.organisaatiotyypit,
        orga.oppilaitostyyppi,
        jsonb_agg(rake.parent_oid) as parent_oids

    from
        organisaatio as orga
    left join organisaatio_rakenne as rake
        on orga.organisaatio_oid = rake.child_oid
    where
        organisaatiotyypit ? '02'
    group by
        orga.organisaatio_oid,
        orga.organisaatio_nimi,
        orga.organisaatiotyypit,
        orga.oppilaitostyyppi
)

select * from final
