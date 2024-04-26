{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with kal3 as (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso3') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        kal3.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso3
    from kal3
    inner join relaatio as rela on
        kal3.koodiuri = rela.alakoodiuri
        and kal3.koodiversio = rela.alakoodiversio
)

select * from final
