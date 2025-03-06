{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['organisaatio_oid']}
    ]
    )
}}

with organisaatio as (
    select distinct on (organisaatio_oid)
        *
    from {{ ref('dw_organisaatio_organisaatio') }}
    order by organisaatio_oid, muokattu desc
),

organisaatiotyyppi as (
    select * from {{ ref('int_koodisto_organisaatiotyyppi') }} where viimeisin_versio
),

organisaatiotyyppirivit as (
    select
        organisaatio_oid,
        jsonb_array_elements_text(organisaatiotyypit) as organisaatiotyyppi
    from organisaatio
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
