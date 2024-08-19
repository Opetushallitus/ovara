{{
  config(
    indexes =[
      {'columns':['versioitu_koodiuri']},
      {'columns':['koodiuri']},
      {'columns':['koodiarvo']},
    ]
  )
}}

with koulutuskoodi as not materialized (
    select
        versioitu_koodiuri,
        koodiuri,
        koodiarvo,
        koodiversio
    from {{ ref('int_koodisto_koulutus') }}

),

kansallinenkoulutusluokitus2016koulutusastetaso1 as not materialized (
    select * from {{ ref('int_koodisto_kkl2016koulutusastetaso1_relaatio_koulutus') }}

),

kansallinenkoulutusluokitus2016koulutusastetaso2 as not materialized (
    select * from {{ ref('int_koodisto_kkl2016koulutusastetaso2_relaatio_koulutus') }}

),

kansallinenkoulutusluokitus2016koulutusalataso1 as not materialized (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso1_relaatio_koulutus') }}

),

kansallinenkoulutusluokitus2016koulutusalataso2 as not materialized (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso2_relaatio_koulutus') }}
),

kansallinenkoulutusluokitus2016koulutusalataso3 as not materialized (
    select * from {{ ref('int_koodisto_kkl2016koulutusalataso3_relaatio_koulutus') }}
),

final as (
    select
        kood.versioitu_koodiuri,
        kood.koodiuri,
        kood.koodiarvo,
        kas1.kansallinenkoulutusluokitus2016koulutusastetaso1,
        kas2.kansallinenkoulutusluokitus2016koulutusastetaso2,
        kal1.kansallinenkoulutusluokitus2016koulutusalataso1,
        kal2.kansallinenkoulutusluokitus2016koulutusalataso2,
        kal3.kansallinenkoulutusluokitus2016koulutusalataso3
    from koulutuskoodi as kood
    inner join kansallinenkoulutusluokitus2016koulutusastetaso1 as kas1
        on kood.versioitu_koodiuri = kas1.versioitu_koodiuri
    inner join kansallinenkoulutusluokitus2016koulutusastetaso2 as kas2
        on kood.versioitu_koodiuri = kas2.versioitu_koodiuri
    inner join kansallinenkoulutusluokitus2016koulutusalataso1 as kal1
        on kood.versioitu_koodiuri = kal1.versioitu_koodiuri
    inner join kansallinenkoulutusluokitus2016koulutusalataso2 as kal2
        on kood.versioitu_koodiuri = kal2.versioitu_koodiuri
    inner join kansallinenkoulutusluokitus2016koulutusalataso3 as kal3
        on kood.versioitu_koodiuri = kal3.versioitu_koodiuri
)

select * from final
