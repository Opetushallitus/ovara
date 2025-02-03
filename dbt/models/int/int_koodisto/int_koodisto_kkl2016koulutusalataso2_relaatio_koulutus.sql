{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with kal2 as (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso2') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        kal2.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso2,
        kal2.koodinimi as kansallinenkoulutusluokitus2016koulutusalataso2_nimi
    from kal2
    inner join relaatio as rela on
        kal2.koodiuri = rela.alakoodiuri
        and kal2.koodiversio = rela.alakoodiversio
)

select * from final
