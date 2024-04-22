with
kunta as
(
    select * from {{ ref('int_koodisto_kunta') }}
),

maakunta as 
(
    select * from {{ ref('int_koodisto_maakunta') }}
),

rel as (
    select * from {{ ref('dw_koodisto_relaatio') }}
    where ylakoodiuri like 'kunta_%'
),

final as (
    select
    kunta.versioitu_koodiuri as kunta_versioitu_koodiuri,
    kunta.koodiuri as kunta_koodiuri,
    kunta.koodiarvo as kunta_koodiarvo,
    kunta.koodiversio as kunta_koodiversio,
    maakunta.versioitu_koodiuri as maakunta_versioitu_koodiuri,
    maakunta.koodiuri as maakunta_koodiuri,
    maakunta.koodiarvo as maakunta_koodiarvo,
    maakunta.koodiversio as maakunta_koodiversio
    from kunta
    join rel on kunta.koodiuri = rel.ylakoodiuri and kunta.koodiversio=rel.ylakoodiversio
    join maakunta on maakunta.koodiuri = rel.alakoodiuri and maakunta.koodiversio=rel.alakoodiversio
)

select 
    {{ dbt_utils.generate_surrogate_key([
    'kunta_versioitu_koodiuri',
    'maakunta_versioitu_koodiuri'
    ]
    ) }} as id,
    * 
from final
