{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select distinct on (resourceid)
        *
    from {{ ref('dw_sure_opiskelija') }}
    order by resourceid, muokattu desc
),

final as (
    select
        resourceid,
        oppilaitosoid as oppilaitos_oid,
        luokkataso,
        luokka,
        henkilooid as henkilo_oid,
        alkupaiva,
        loppupaiva,
        muokattu,
        poistettu,
        source
    from raw
)

select * from final
