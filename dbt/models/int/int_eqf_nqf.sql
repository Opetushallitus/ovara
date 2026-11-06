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

koulutus as (
    select
        koulutus_oid,
        split_part(
            jsonb_array_elements_text(koulutuksetkoodiuri),
            '#',
            1
        ) as koulutus_koodi
    from {{ ref('int_kouta_koulutus') }}
),

eqf as (
    select
        r.ylakoodiuri as koulutus_koodi,
        e.koodiarvo as eqf
    from relaatio as r
    join eqf_source as e
      on e.koodiuri = r.alakoodiuri
  ),

nqf as (
    select
        r.ylakoodiuri as koulutus_koodi,
        n.koodiarvo as nqf
    from relaatio as r
    join nqf_source as n
      on n.koodiuri = r.alakoodiuri
),

eqf_nqf as (
    select
        koulutus_koodi,
        eqf,
        nqf
    from eqf
    full join nqf using (koulutus_koodi)
),

final as (
    select
        koulutus.koulutus_oid,
        jsonb_agg(distinct eqf_nqf.eqf::int) filter (where eqf_nqf.eqf is not null) as eqf,
        jsonb_agg(distinct eqf_nqf.nqf::int) filter (where eqf_nqf.nqf is not null) as nqf
    from koulutus
    left join eqf_nqf on koulutus.koulutus_koodi = eqf_nqf.koulutus_koodi
    group by koulutus.koulutus_oid
)

select * from final
--select * from final
order by koulutus_oid
