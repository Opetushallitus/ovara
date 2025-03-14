{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['jarjestyspaikka_oid']}
    ]
    )
}}

with organisaatio as (
    select * from {{ ref('int_organisaatio') }}
),

org_levels as (
    select
        lev1.organisaatio_oid as oid_level1,
        lev1.organisaatio_nimi as nimi_level1,
        lev1.organisaatiotyypit as tyypit_level1,
        lev2.organisaatio_oid as oid_level2,
        lev2.organisaatio_nimi as nimi_level2,
        lev2.organisaatiotyypit as tyypit_level2,
        lev3.organisaatio_oid as oid_level3,
        lev3.organisaatio_nimi as nimi_level3,
        lev3.organisaatiotyypit as tyypit_level3,
        lev4.organisaatio_oid as oid_level4,
        lev4.organisaatio_nimi as nimi_level4,
        lev4.organisaatiotyypit as tyypit_level4
    from organisaatio as lev1
    left join organisaatio as lev2 on lev1.ylempi_organisaatio = lev2.organisaatio_oid
    left join organisaatio as lev3 on lev2.ylempi_organisaatio = lev3.organisaatio_oid
    left join organisaatio as lev4 on lev3.ylempi_organisaatio = lev4.organisaatio_oid
),

logic as (
    select
        oid_level1 as jarjestyspaikka_oid,
        case when tyypit_level3 ? '02' then nimi_level3 end as one,
        case when tyypit_level2 ? '01' then null else nimi_level2 end as two,
        nimi_level1 as three,
        case
            when tyypit_level1 ? '03' then nimi_level1
        end as toimipiste_nimi,
        case
            when tyypit_level1 ? '03' then oid_level1
        end as toimipiste,
        case
            when tyypit_level1 ? '02' then nimi_level1
            when tyypit_level2 ? '02' then nimi_level2
            when tyypit_level3 ? '02' then nimi_level3
            when tyypit_level4 ? '02' then nimi_level4
        end as oppilaitos_nimi,
        case
            when tyypit_level1 ? '02' then oid_level1
            when tyypit_level2 ? '02' then oid_level2
            when tyypit_level3 ? '02' then oid_level3
            when tyypit_level4 ? '02' then oid_level4
        end as oppilaitos,
        case
            when tyypit_level1 ? '01' then oid_level1
            when tyypit_level2 ? '01' then oid_level2
            when tyypit_level3 ? '01' then oid_level3
            when tyypit_level4 ? '01' then oid_level4
        end as koulutustoimija,
        case
            when tyypit_level1 ? '01' then nimi_level1
            when tyypit_level2 ? '01' then nimi_level2
            when tyypit_level3 ? '01' then nimi_level3
            when tyypit_level4 ? '01' then nimi_level4
        end as koulutustoimija_nimi

    from org_levels
),

final as (

    select
        jarjestyspaikka_oid,
        case
            when two is null
                then jsonb_build_object(
                    'fi', three ->> 'fi',
                    'sv', three ->> 'sv',
                    'en', three ->> 'en'
                )
            when one is null
                then jsonb_build_object(
                    'fi', concat(two ->> 'fi', ', ', three ->> 'fi'),
                    'sv', concat(two ->> 'sv', ', ', three ->> 'sv'),
                    'en', concat(two ->> 'en', ', ', three ->> 'en')
                )
            else
                jsonb_build_object(
                    'fi', concat(one ->> 'fi', ', ', two ->> 'fi', ', ', three ->> 'fi'),
                    'sv', concat(one ->> 'sv', ', ', two ->> 'sv', ', ', three ->> 'sv'),
                    'en', concat(one ->> 'en', ', ', two ->> 'en', ', ', three ->> 'en')
                )
        end
        as organisaatio_nimi,
        toimipiste,
        toimipiste_nimi,
        oppilaitos,
        oppilaitos_nimi,
        koulutustoimija,
        koulutustoimija_nimi
    from logic
)

select * from final
