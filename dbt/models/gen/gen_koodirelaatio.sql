{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['versioitu_alakoodiuri', 'versioitu_ylakoodiuri']}
    ]
    )
}}
with relaatio as (
    select * from {{ ref('int_koodisto_relaatio') }}
)

select
    alakoodiuri || '#' || alakoodiversio as versioitu_alakoodiuri,
    ylakoodiuri || '#' || ylakoodiversio as versioitu_ylakoodiuri,
    relaatiotyyppi,
    relaatioversio,
    alakoodiuri,
    alakoodiversio,
    ylakoodiuri,
    ylakoodiversio
from relaatio
