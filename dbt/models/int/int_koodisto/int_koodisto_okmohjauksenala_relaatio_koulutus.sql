{{
  config(
    indexes=[
        {'columns':['versioitu_koodiuri']}
    ]
    )
}}

with okma as (
    select * from {{ ref('int_koodisto_okmohjauksenala') }}
),

relaatio as (
    select * from {{ ref('int_koodisto_relaatio_koulutus') }}
),

final as (
    select
        rela.ylakoodiuri || '#' || rela.ylakoodiversio as versioitu_koodiuri,
        okma.koodiarvo as okmohjauksenala
    from okma
    inner join relaatio as rela on
        okma.koodiuri = rela.alakoodiuri
        and okma.koodiversio = rela.alakoodiversio
)

select * from final
