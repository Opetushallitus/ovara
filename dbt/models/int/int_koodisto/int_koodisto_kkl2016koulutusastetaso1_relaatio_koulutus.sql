{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with kas1 as (
    select * from {{ ref('int_koodisto_kkl2016koulutusastetaso1') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        kas1.koodiarvo as kansallinenkoulutusluokitus2016koulutusastetaso1
    from kas1
    inner join relaatio as rela on
        kas1.koodiuri = rela.alakoodiuri
        and kas1.koodiversio = rela.alakoodiversio
)

select * from final
