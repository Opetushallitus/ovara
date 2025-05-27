{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['haun_tyyppi']},
        {'columns': ['koulutuksen_alkamiskausi'], 'type': 'gin' }
    ]
    )
}}

with haku as (
    select * from {{ ref('int_haku') }}
),

toteutus as (
    select distinct
        haku_oid,
        koulutuksen_alkamiskausikoodi
    from {{ ref('int_toteutus_koulutuksen_alkamiskausi') }}
    where
        koulutuksen_alkamiskausikoodi is not null
        and haku_oid is not null
),

hakukohde as (
    select
        haku_oid,
        koulutuksen_alkamiskausikoodi -> 0 as koulutuksen_alkamiskausikoodi
    from {{ ref('int_hakukohde') }}
    where
        koulutuksen_alkamiskausi is not null
        and (
            koulutuksen_alkamiskausi != '[{}]'::jsonb
            or koulutuksen_alkamiskausi != '[]'::jsonb
        )
),

alkamisajankohta as (
    select
        haku_oid,
        jsonb_agg(koulutuksen_alkamiskausikoodi) as koulutuksen_alkamiskausi
    from
        (
            select
                haku_oid,
                case
                    when koulutuksen_alkamiskausikoodi = '[{}]'::jsonb then '{"type": "eialkamiskautta"}'::jsonb
                    else coalesce(koulutuksen_alkamiskausikoodi -> 0, '{"type": "eialkamiskautta"}'::jsonb)
                end as koulutuksen_alkamiskausikoodi
            from haku

            union

            select
                haku_oid,
                koulutuksen_alkamiskausikoodi
            from hakukohde

            union
            select
                haku_oid,
                koulutuksen_alkamiskausikoodi
            from toteutus
        ) as rivi
    group by haku_oid
)

select
    haku.haku_oid,
    haku.haku_nimi,
    alko.koulutuksen_alkamiskausi,
    haku.haun_tyyppi
from haku
left join alkamisajankohta as alko on haku.haku_oid = alko.haku_oid
