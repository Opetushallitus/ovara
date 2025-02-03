{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with kas2 as (
    select * from {{ ref('int_koodisto_kkl2016koulutusastetaso2') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        kas2.koodiarvo as kansallinenkoulutusluokitus2016koulutusastetaso2,
        kas2.koodinimi as kansallinenkoulutusluokitus2016koulutusastetaso2_nimi
    from kas2
    inner join relaatio as rela on
        kas2.koodiuri = rela.alakoodiuri
        and kas2.koodiversio = rela.alakoodiversio
)

select * from final
