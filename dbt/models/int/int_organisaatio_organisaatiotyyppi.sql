{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['organisaatio_oid']}
    ]
    )
}}

with organisaatio as (
    select
        *,
        row_number() over (partition by organisaatio_oid order by muokattu desc) as rownr
    from {{ ref('dw_organisaatio_organisaatio') }}
),

organisaatiotyyppi as (
    select * from {{ ref('int_koodisto_organisaatiotyyppi') }} where viimeisin_versio
),

organisaatiotyyppirivit as (
    select
        organisaatio_oid,
        jsonb_array_elements_text(organisaatiotyypit) as organisaatiotyyppi
    from organisaatio
    where rownr = 1
),

final as (
    select
        orgr.organisaatio_oid,
        jsonb_agg(orgt.koodiarvo) as organisaatiotyypit
    from organisaatiotyyppirivit as orgr
    inner join organisaatiotyyppi as orgt on orgr.organisaatiotyyppi = orgt.koodiuri
    group by orgr.organisaatio_oid
)

select * from final
