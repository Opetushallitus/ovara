{{
  config(
    materialized = 'table'
  )
}}

with eqf_source as (
    select
        koodiuri,
        koodiarvo
    from {{ ref('int_koodisto_eqf') }}
    where viimeisin_versio
),

nqf_source as (
    select
        koodiuri,
        koodiarvo
    from {{ ref('int_koodisto_nqf') }}
    where viimeisin_versio
),

relaatio as (
    select distinct
        alakoodiuri,
        ylakoodiuri
    from {{ ref('int_koodisto_relaatio') }}
    where ylakoodiuri like 'koulutus%'
    and (
        alakoodiuri like 'eqf%'
        or alakoodiuri like 'nqf%'
    )
),

eqf as (
    select
        r.ylakoodiuri,
        a.koodiarvo as eqf
    from relaatio as r
    join eqf_source as a
      on a.koodiuri = r.alakoodiuri
),

nqf as (
    select
        r.ylakoodiuri,
        a.koodiarvo as nqf
    from relaatio as r
    join nqf_source as a
      on a.koodiuri = r.alakoodiuri
),

final as (
    select distinct on (ylakoodiuri)
        ylakoodiuri as koulutus_koodi,
        eqf,
        nqf
    from eqf
    full join nqf using (ylakoodiuri)
    order by ylakoodiuri
)

select * from final
order by koulutus_koodi
