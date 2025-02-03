{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with kal1 as (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso1') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        kal1.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso1,
        kal1.koodinimi as kansallinenkoulutusluokitus2016koulutusalataso1_nimi
    from
        kal1
    inner join relaatio as rela on
        kal1.koodiuri = rela.alakoodiuri
        and kal1.koodiversio = rela.alakoodiversio
)

select * from final
