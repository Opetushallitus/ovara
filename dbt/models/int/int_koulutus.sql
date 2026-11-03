with koulutus as (
    select * from {{ ref('int_kouta_koulutus') }}
),

alat as (
    select
        versioitu_koodiuri,
        kansallinenkoulutusluokitus2016koulutusalataso2
    from {{ ref('int_koodisto_kkl2016koulutusalataso2_relaatio_koulutus') }}
),

eqf_nqf as (
    select * from  {{ ref('int_eqf_nqf') }}
),

final as (
    select
        {{ dbt_utils.star (
            from = ref('int_kouta_koulutus'),
            except = ['koulutusalakoodiurit']
        ) }},
        coalesce(
            kala.koulutusala,
            case
                when koul.koulutusalakoodiurit <> '[]'::jsonb
                    then koul.koulutusalakoodiurit
                else '["muu/tuntematon"]'::jsonb
            end
        ) as koulutusalakoodiurit,
        eqnf.eqf,
        eqnf.nqf
    from koulutus as koul
    left join lateral (
        select (
            jsonb_agg(
                distinct
                'kansallinenkoulutusluokitus2016koulutusalataso2'
                || '_'
                || alat.kansallinenkoulutusluokitus2016koulutusalataso2
                || '#1'
            )
            filter (
                where alat.kansallinenkoulutusluokitus2016koulutusalataso2 is not null
            )
        ) as koulutusala
        from jsonb_array_elements_text(koul.koulutuksetkoodiuri) as kku (koulutus_koodi)
        left join alat on kku.koulutus_koodi = alat.versioitu_koodiuri
    ) as kala on true
    left join eqf_nqf as eqnf on split_part(koul.koulutuksetkoodiuri ->> 0, '#', 1) = eqnf.koulutus_koodi
)

select * from final
