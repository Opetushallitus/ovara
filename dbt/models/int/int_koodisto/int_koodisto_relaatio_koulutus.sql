{{
  config(
    indexes = [
        {'columns': ['alakoodisto']}
    ]
    )
}}


with raw as (
    select distinct on (ylakoodiuri, split_part(alakoodiuri, '_', 1), relaatioversio)
        split_part(alakoodiuri, '_', 1) as alakoodisto,
        alakoodiuri,
        alakoodiversio,
        ylakoodiuri,
        ylakoodiversio,
        relaatioversio
    from {{ ref('dw_koodisto_relaatio') }}
    where
        split_part(ylakoodiuri, '_', 1) = 'koulutus'
        and alakoodiuri like 'kansallinenkoulutusluokitus2016%'
        or alakoodiuri like 'okmohjauksenala%'
    order by ylakoodiuri, split_part(alakoodiuri, '_', 1), relaatioversio
)

select * from raw
