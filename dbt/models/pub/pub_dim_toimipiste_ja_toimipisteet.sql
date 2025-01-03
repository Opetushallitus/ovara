with toimipiste as (
    select * from {{ ref('pub_dim_toimipiste') }}
),

final as (
    select
        toim.organisaatio_oid,
        toim.organisaatio_nimi,
        toim.organisaatiotyypit,
        toim.oppilaitostyyppi,
        toim.parent_oids,
        coalesce(
            jsonb_agg(distinct alto.*) filter (
                where alto.organisaatio_oid is not null
            ),
            '[]'::jsonb
        ) as children
    from
        toimipiste as toim
    left join toimipiste as alto
        on alto.parent_oids ? toim.organisaatio_oid
    group by
        toim.organisaatio_oid,
        toim.organisaatio_nimi,
        toim.organisaatiotyypit,
        toim.parent_oids,
        toim.oppilaitostyyppi
)

select * from final
