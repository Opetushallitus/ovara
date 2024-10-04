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

okmohjauksenala as not materialized (
    select * from {{ ref('int_koodisto_okmohjauksenala_relaatio_koulutus') }}
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
        kal3.kansallinenkoulutusluokitus2016koulutusalataso3,
        case when left(kood.koodiarvo, 1) = '6' then 1::int else 0::int end as alempi_kk_aste,
        case when left(kood.koodiarvo, 1) = '7' then 1::int else 0::int end as ylempi_kk_aste,
        case when left(kood.koodiarvo, 1) = '8' then 1::bool else 0::bool end as jatkotutkinto,
        case
            when kood.koodiarvo in ('772100', '772101', '772200', '772201', '772300', '772301')
                then 1::bool
            else 0::bool
        end as laakis,
        okma.okmohjauksenala
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
    left join okmohjauksenala as okma
        on kood.versioitu_koodiuri = okma.versioitu_koodiuri
)

select * from final
