{{
  config(
    indexes =[
      {'columns':['versioitu_koodiuri']},
      {'columns':['koodiuri']},
    ]
  )
}}

with koodisto as (
    select
        koodiarvo,
        koodiuri,
        koodiversio,
        koodistouri
    from {{ ref('dw_koodisto_koodi') }}
),

relaatio as (
    select
        id,
        alakoodiuri,
        alakoodiversio,
        relaatioversio,
        ylakoodiuri,
        ylakoodiversio
    from {{ ref('dw_koodisto_relaatio') }}
),

koulutuskoodi as (
    select -- noqa: ST06
        koodiuri || '#' || koodiversio::varchar as versioitu_koodiuri,
        koodiuri,
        koodiarvo::int,
        koodiversio
    from koodisto
    where koodistouri = 'koulutus'
),

kansallinenkoulutusluokitus2016koulutusastetaso1 as (
    select
        rela.ylakoodiuri,
        rela.ylakoodiversio,
        kood.koodiarvo,
        kood.koodiuri,
        kood.koodiversio
    from koodisto as kood
    inner join relaatio as rela on kood.koodiuri = rela.alakoodiuri and kood.koodiversio = rela.alakoodiversio
    where kood.koodistouri = 'kansallinenkoulutusluokitus2016koulutusastetaso1'
),

kansallinenkoulutusluokitus2016koulutusastetaso2 as (
    select
        rela.ylakoodiuri,
        rela.ylakoodiversio,
        kood.koodiarvo,
        kood.koodiuri,
        kood.koodiversio
    from koodisto as kood
    inner join relaatio as rela on kood.koodiuri = rela.alakoodiuri and kood.koodiversio = rela.alakoodiversio
    where kood.koodistouri = 'kansallinenkoulutusluokitus2016koulutusastetaso2'
),

kansallinenkoulutusluokitus2016koulutusalataso1 as (
    select
        rela.ylakoodiuri,
        rela.ylakoodiversio,
        kood.koodiarvo,
        kood.koodiuri,
        kood.koodiversio
    from koodisto as kood
    inner join relaatio as rela on kood.koodiuri = rela.alakoodiuri and kood.koodiversio = rela.alakoodiversio
    where kood.koodistouri = 'kansallinenkoulutusluokitus2016koulutusalataso1'
),

kansallinenkoulutusluokitus2016koulutusalataso2 as (
    select
        rela.ylakoodiuri,
        rela.ylakoodiversio,
        kood.koodiarvo,
        kood.koodiuri,
        kood.koodiversio
    from koodisto as kood
    inner join relaatio as rela on kood.koodiuri = rela.alakoodiuri and kood.koodiversio = rela.alakoodiversio
    where kood.koodistouri = 'kansallinenkoulutusluokitus2016koulutusalataso2'
),

kansallinenkoulutusluokitus2016koulutusalataso3 as (
    select
        rela.ylakoodiuri,
        rela.ylakoodiversio,
        kood.koodiarvo,
        kood.koodiuri,
        kood.koodiversio
    from koodisto as kood
    inner join relaatio as rela on kood.koodiuri = rela.alakoodiuri and kood.koodiversio = rela.alakoodiversio
    where kood.koodistouri = 'kansallinenkoulutusluokitus2016koulutusalataso3'
),

final as (
    select
        kood.versioitu_koodiuri,
        kood.koodiuri,
        kood.koodiarvo,
        kas1.koodiarvo as kansallinenkoulutusluokitus2016koulutusastetaso1,
        kas2.koodiarvo as kansallinenkoulutusluokitus2016koulutusastetaso2,
        kal1.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso1,
        kal2.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso2,
        kal3.koodiarvo as kansallinenkoulutusluokitus2016koulutusalataso3
    from koulutuskoodi as kood
    inner join kansallinenkoulutusluokitus2016koulutusastetaso1 as kas1
        on kood.koodiuri = kas1.ylakoodiuri and kood.koodiversio = kas1.ylakoodiversio
    inner join kansallinenkoulutusluokitus2016koulutusastetaso2 as kas2
        on kood.koodiuri = kas2.ylakoodiuri and kood.koodiversio = kas2.ylakoodiversio
    inner join kansallinenkoulutusluokitus2016koulutusalataso1 as kal1
        on kood.koodiuri = kal1.ylakoodiuri and kood.koodiversio = kal1.ylakoodiversio
    inner join kansallinenkoulutusluokitus2016koulutusalataso2 as kal2
        on kood.koodiuri = kal2.ylakoodiuri and kood.koodiversio = kal2.ylakoodiversio
    inner join kansallinenkoulutusluokitus2016koulutusalataso3 as kal3
        on kood.koodiuri = kal3.ylakoodiuri and kood.koodiversio = kal3.ylakoodiversio
)

select * from final
