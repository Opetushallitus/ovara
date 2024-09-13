{{
  config(
    indexes = [
        {'columns': ['alakoodisto']}
    ]
    )
}}


with raw as (
    select
        split_part(alakoodiuri, '_', 1) as alakoodisto,
        alakoodiuri,
        alakoodiversio,
        ylakoodiuri,
        ylakoodiversio,
        relaatioversio,
        row_number() over (partition by ylakoodiuri, split_part(alakoodiuri, '_', 1), relaatioversio) as rownr
    from {{ ref('dw_koodisto_relaatio') }}
    where
        split_part(ylakoodiuri, '_', 1) = 'koulutus'
        and alakoodiuri like 'kansallinenkoulutusluokitus2016%'
        or alakoodiuri like 'okmohjauksenala%'
)

select * from raw
where rownr = 1