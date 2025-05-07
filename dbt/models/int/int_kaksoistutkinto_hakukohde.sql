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
        lomake_id,
        hakukohde,
        jsonb_object_keys(tiedot) as keys,
        tiedot
    from {{ ref('int_ataru_hakemus') }}
    where
        tiedot ?| array[
            '4fe08958-c0b7-4847-8826-e42503caa662',
            '32b8440f-d6f0-4a8b-8f67-873344cc3488',
            'lukio_opinnot_ammatillisen_perustutkinnon_ohella',
            'ammatilliset_opinnot_lukio_opintojen_ohella-amm'
        ]
),

hakukohde as (
    select * from {{ ref('int_lomake_hakukohde') }}
),

rows as (
    select
        hakemus_oid,
        hakukohde,
        lomake_id,
        split_part(keys, '_', -1) as hakukohde_oid,
        (regexp_match(keys::text, '.*(?=_)'))[1] as kysymys_id,
        tiedot ->> keys as arvo
    from raw
    where
        (
            keys like '4fe08958-c0b7-4847-8826-e42503caa662%'
            or keys like '32b8440f-d6f0-4a8b-8f67-873344cc3488%'
            or keys like 'lukio_opinnot_ammatillisen_perustutkinnon_ohella%'
            or keys like 'ammatilliset_opinnot_lukio_opintojen_ohella%'
        )
        and tiedot ->> keys is not null
),

int as (
    select
        rows.hakemus_oid,
        coalesce(rows.kysymys_id, rows.hakukohde_oid) as kysymys_id,
        rows.arvo,
        hako.hakukohde_oid
    from rows
    inner join hakukohde as hako on
    	rows.lomake_id = hako.lomake_id
    	and rows.hakukohde ? hako.hakukohde_oid
    	and (
    		rows.hakukohde_oid = hako.kysymys_id
    		or rows.hakukohde_oid = hako.hakukohde_oid
    		)
        and hako.kysymys_id in (
            '4fe08958-c0b7-4847-8826-e42503caa662',
            '32b8440f-d6f0-4a8b-8f67-873344cc3488',
            'lukio_opinnot_ammatillisen_perustutkinnon_ohella',
            'ammatilliset_opinnot_lukio_opintojen_ohella-amm'
    	)
),

final as (
    select
    	hakemus_oid,
    	hakukohde_oid,
        case
            when kysymys_id = '32b8440f-d6f0-4a8b-8f67-873344cc3488' and arvo = '0' then true
            when kysymys_id = '32b8440f-d6f0-4a8b-8f67-873344cc3488' and arvo = '1' then false
            when kysymys_id = 'lukio_opinnot_ammatillisen_perustutkinnon_ohella' and arvo = '0' then true
            when kysymys_id = 'lukio_opinnot_ammatillisen_perustutkinnon_ohella' and arvo = '1' then false
            when kysymys_id = 'ammatilliset_opinnot_lukio_opintojen_ohella' and arvo = '0' then true
            when kysymys_id = 'ammatilliset_opinnot_lukio_opintojen_ohella' and arvo = '1' then false
            when kysymys_id = '4fe08958-c0b7-4847-8826-e42503caa662' and arvo = '0' then true
            when kysymys_id = '4fe08958-c0b7-4847-8826-e42503caa662' and arvo = '1' then false
       end as kaksoistutkinto_kiinnostaa
    from int
)

select
    {{ hakutoive_id() }},
    *
from final
