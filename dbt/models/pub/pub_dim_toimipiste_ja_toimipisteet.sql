with toimipiste as (
    select * from {{ ref('pub_dim_toimipiste') }}
),

tyhja_array as (
    select
        *,
        '[]'::jsonb as children
    from toimipiste
),

final as (
    select
        toim.organisaatio_oid,
        toim.organisaatio_nimi,
        toim.organisaatiotyypit,
        toim.oppilaitostyyppi,
        toim.tila,
        toim.parent_oids,
        coalesce(
            jsonb_agg(distinct alto.*) filter (
                where alto.organisaatio_oid is not null
            ),
            '[]'::jsonb
        ) as children
    from
        toimipiste as toim
    left join
        tyhja_array as alto
        on alto.parent_oids ? toim.organisaatio_oid and alto.organisaatio_oid != toim.organisaatio_oid
    group by
        toim.organisaatio_oid,
        toim.organisaatio_nimi,
        toim.organisaatiotyypit,
        toim.parent_oids,
        toim.oppilaitostyyppi,
        toim.tila
)

select * from final
