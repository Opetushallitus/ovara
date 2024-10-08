with
maa as (
    select * from {{ ref('int_koodisto_maa_2') }}
),

valtioryhma as (
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
        valtioryhma.koodiversio as valtioryhma_koodiversio,
        rel.relaatioversio
    from maa
    inner join rel on maa.koodiuri = rel.ylakoodiuri and maa.koodiversio = rel.ylakoodiversio
    inner join valtioryhma on rel.alakoodiuri = valtioryhma.koodiuri and rel.alakoodiversio = valtioryhma.koodiversio
)

select
    {{ dbt_utils.generate_surrogate_key([
    'maa_versioitu_koodiuri',
    'valtioryhma_versioitu_koodiuri'
    ]
    ) }} as id,
    *
from final
