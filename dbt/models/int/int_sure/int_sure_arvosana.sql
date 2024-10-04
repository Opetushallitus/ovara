{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by resourceid order by muokattu desc) as row_nr
    from {{ ref('dw_sure_arvosana') }}
),

int as (
    select
        *
    from raw
    where row_nr = 1
),

final as (
    select
        resourceid,
        suoritus,
        arvosana,
        asteikko,
        aine,
        lisatieto,
        valinnainen,
        muokattu,
        deleted,
        pisteet,
        myonnetty,
        source,
        jarjestys,
        arvot
    from int
)

select * from final
