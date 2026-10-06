with source as (
    select
        toteutus_oid,
        maksut
    from {{ ref('int_kouta_toteutus') }}
    where maksut is not null
),

final as (
    select
        toteutus_oid,
        maksu ->> 'maksullisuustyyppi' as maksullisuustyyppi,
        coalesce((maksu ->> 'maksunMaara')::numeric(18, 2), 0) as maksun_maara
    from source as sorc
    inner join lateral (select jsonb_array_elements(sorc.maksut)) as maksut (maksu) on true
)

select * from final
