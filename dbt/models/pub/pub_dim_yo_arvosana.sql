{{
    config(
        materialized = 'table',
        indexes = [
            {'columns':['resourceid']},
            {'columns':['henkilooid']},
        ]
    )
}}

with arvosana as (
    select * from {{ ref('int_sure_arvosana') }} where asteikko='YO'
),

suoritus as (
    select * from {{ ref('int_sure_suoritus') }}
),

int as (
    select
        arvosana.resourceid,
        arvosana.suoritus,
        arvosana.arvosana,
        arvosana.asteikko,
        arvosana.aine,
        arvosana.lisatieto,
        arvosana.valinnainen,
        arvosana.muokattu,
        arvosana.deleted,
        arvosana.pisteet,
        arvosana.myonnetty,
        arvosana.source,
        arvosana.jarjestys,
        arvosana.arvot,
        suoritus.henkilooid as henkilooid,
        suoritus.tila as tila,        
        suoritus.valmistuminen as pvm
    from arvosana 
    left join suoritus on arvosana.suoritus = suoritus.resourceid
)

select * from int
