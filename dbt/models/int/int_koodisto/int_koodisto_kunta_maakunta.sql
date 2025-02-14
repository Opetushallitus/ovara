{{
    config (
        indexes = [
            {'columns': ['kunta_koodiarvo']}
        ]
    )

}}

with
kunta as (
    select * from {{ ref('int_koodisto_kunta') }} where viimeisin_versio
),

maakunta as (
    select * from {{ ref('int_koodisto_maakunta') }} where viimeisin_versio
),

rel as (
    select * from {{ ref('dw_koodisto_relaatio') }}
    where ylakoodiuri like 'kunta_%'
),

kunta_maakunta_relaatio as (
    select
        knta.versioitu_koodiuri as kunta_versioitu_koodiuri,
        knta.koodiuri as kunta_koodiuri,
        knta.koodiarvo as kunta_koodiarvo,
        knta.koodiversio as kunta_koodiversio,
        mkta.versioitu_koodiuri as maakunta_versioitu_koodiuri,
        mkta.koodiuri as maakunta_koodiuri,
        mkta.koodiarvo as maakunta_koodiarvo,
        mkta.koodiversio as maakunta_koodiversio,
        rela.relaatioversio,
        max(relaatioversio) over (partition by knta.koodiuri) = rela.relaatioversio as viimeisin_versio
    from kunta as knta
    inner join rel as rela on knta.koodiuri = rela.ylakoodiuri and knta.koodiversio = rela.ylakoodiversio
    inner join maakunta as mkta on rela.alakoodiuri = mkta.koodiuri and rela.alakoodiversio = mkta.koodiversio
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
        'kunta_versioitu_koodiuri',
        'maakunta_versioitu_koodiuri'
        ]
        ) }} as id,
        *
    from kunta_maakunta_relaatio

)

select * from final
