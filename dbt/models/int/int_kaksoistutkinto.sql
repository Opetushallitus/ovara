{{
  config(
    indexes = [
        {'columns': ['hakutoive_id']}
    ]
    )
}}

with raw as ( --noqa: PRS
    select
        hakemus_oid,
        jsonb_object_keys(tiedot) as keys,
        tiedot
    from {{ ref('int_ataru_hakemus') }}
    where tiedot ?|
        array[
            '4fe08958-c0b7-4847-8826-e42503caa662',
            '32b8440f-d6f0-4a8b-8f67-873344cc3488',
            'kaksoistutkinto-lukio',
            'kaksoistutkinto-amm'
        ]
),

rows as (
    select * from raw where
    keys like '4fe08958-c0b7-4847-8826-e42503caa662_%'
    or keys like '32b8440f-d6f0-4a8b-8f67-873344cc3488_%'
    or keys like 'kaksoistutkinto-lukio_%'
    or keys like 'kaksoistutkinto-amm_%'
),

final as (
    select
        hakemus_oid,
        split_part(keys,'_',2) as hakukohde_oid,
        (tiedot ->> keys)::boolean as kaksoistutkinto_kiinnostaa
    from rows
)

select
    {{ hakutoive_id() }},
    *
    from final
