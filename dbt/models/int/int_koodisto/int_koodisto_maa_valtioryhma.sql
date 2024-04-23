with
maa as
(
    select * from {{ ref('int_koodisto_maa_2') }}
),

valtioryhma as 
(
    select * from {{ ref('int_koodisto_valtioryhma') }}
),

rel as (
    select * from {{ ref('dw_koodisto_relaatio') }}
    where ylakoodiuri like 'maatjavaltiot2_%'
),

final as (
    select
    maa.versioitu_koodiuri as maa_versioitu_koodiuri,
    maa.koodiuri as maa_koodiuri,
    maa.koodiarvo as maa_koodiarvo,
    maa.koodiversio as maa_koodiversio,
    valtioryhma.versioitu_koodiuri as valtioryhma_versioitu_koodiuri,
    valtioryhma.koodiuri as valtioryhma_koodiuri,
    valtioryhma.koodiarvo as valtioryhma_koodiarvo,
    valtioryhma.koodiversio as valtioryhma_koodiversio
    from maa
    join rel on maa.koodiuri = rel.ylakoodiuri and maa.koodiversio=rel.ylakoodiversio
    join valtioryhma on valtioryhma.koodiuri = rel.alakoodiuri and valtioryhma.koodiversio=rel.alakoodiversio
)

select 
    {{ dbt_utils.generate_surrogate_key([
    'maa_versioitu_koodiuri',
    'valtioryhma_versioitu_koodiuri'
    ]
    ) }} as id,
    * 
from final
