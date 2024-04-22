{{
  config(
    indexes =[
      {'columns':['versioitu_koodiuri']},
      {'columns':['koodiuri']},
    ]
  )
}}

with koodisto as
(
    select 
    koodiarvo,
    koodiuri,
    koodiversio,
    koodistouri
    from {{ ref('dw_koodisto_koodi') }}
),

relaatio as
(
    select 
    id,
    alakoodiuri,
    alakoodiversio,
    relaatioversio,
    ylakoodiuri,
    ylakoodiversio
     from {{ ref('dw_koodisto_relaatio') }}
),
koulutuskoodi as
(
    select 
    koodiuri || '#' || koodiversio::varchar as versioitu_koodiuri,
    koodiuri,
    koodiarvo::int,
    koodiversio
    from koodisto
    where koodistouri='koulutus'
),

kansallinenkoulutusluokitus2016koulutusastetaso1 as
(
    select
    r.ylakoodiuri,
    r.ylakoodiversio,
    koodiarvo,
    koodiuri,
    koodiversio
    from koodisto k
    join relaatio r on k.koodiuri=r.alakoodiuri and k.koodiversio=r.alakoodiversio
    where koodistouri='kansallinenkoulutusluokitus2016koulutusastetaso1'
),
kansallinenkoulutusluokitus2016koulutusastetaso2 as
(
    select
    r.ylakoodiuri,
    r.ylakoodiversio,
    koodiarvo,
    koodiuri,
    koodiversio
    from koodisto k
    join relaatio r on k.koodiuri=r.alakoodiuri and k.koodiversio=r.alakoodiversio
    where koodistouri='kansallinenkoulutusluokitus2016koulutusastetaso2'
),
kansallinenkoulutusluokitus2016koulutusalataso1 as
(
    select
    r.ylakoodiuri,
    r.ylakoodiversio,
    koodiarvo,
    koodiuri,
    koodiversio
    from koodisto k
    join relaatio r on k.koodiuri=r.alakoodiuri and k.koodiversio=r.alakoodiversio
    where koodistouri='kansallinenkoulutusluokitus2016koulutusalataso1'
),
kansallinenkoulutusluokitus2016koulutusalataso2 as
(
    select
    r.ylakoodiuri,
    r.ylakoodiversio,
    koodiarvo,
    koodiuri,
    koodiversio
    from koodisto k
    join relaatio r on k.koodiuri=r.alakoodiuri and k.koodiversio=r.alakoodiversio
    where koodistouri='kansallinenkoulutusluokitus2016koulutusalataso2'
),
kansallinenkoulutusluokitus2016koulutusalataso3 as
(
    select
    r.ylakoodiuri,
    r.ylakoodiversio,
    koodiarvo,
    koodiuri,
    koodiversio
    from koodisto k
    join relaatio r on k.koodiuri=r.alakoodiuri and k.koodiversio=r.alakoodiversio
    where koodistouri='kansallinenkoulutusluokitus2016koulutusalataso3'
)


select 
k.versioitu_koodiuri,
k.koodiuri,
k.koodiarvo,
kaste1.koodiarvo as  kansallinenkoulutusluokitus2016koulutusastetaso1,
kaste2.koodiarvo as  kansallinenkoulutusluokitus2016koulutusastetaso2,
kala1.koodiarvo as  kansallinenkoulutusluokitus2016koulutusalataso1,
kala2.koodiarvo as  kansallinenkoulutusluokitus2016koulutusalataso2,
kala3.koodiarvo as  kansallinenkoulutusluokitus2016koulutusalataso3
from 
koulutuskoodi k
join kansallinenkoulutusluokitus2016koulutusastetaso1 kaste1 on k.koodiuri=kaste1.ylakoodiuri and k.koodiversio=kaste1.ylakoodiversio
join kansallinenkoulutusluokitus2016koulutusastetaso2 kaste2 on k.koodiuri=kaste2.ylakoodiuri and k.koodiversio=kASTE2.ylakoodiversio
join kansallinenkoulutusluokitus2016koulutusalataso1 kala1 on k.koodiuri=kala1.ylakoodiuri and k.koodiversio=kala1.ylakoodiversio
join kansallinenkoulutusluokitus2016koulutusalataso2 kala2 on k.koodiuri=kala2.ylakoodiuri and k.koodiversio=kala2.ylakoodiversio
join kansallinenkoulutusluokitus2016koulutusalataso3 kala3 on k.koodiuri=kala3.ylakoodiuri and k.koodiversio=kala3.ylakoodiversio
