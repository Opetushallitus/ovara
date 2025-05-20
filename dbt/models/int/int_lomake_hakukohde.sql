{{
  config(
	materialized = 'table',
	indexes = [
		{'columns': ['lomake_id','kysymys_id']},
		{'columns': ['hakukohde_oid']}
	]
	)
}}

with source as not materialized (
    select distinct on (id)
        content,
        id as lomake_id
    from {{ ref('dw_ataru_lomake') }}
    where
        content @> '[{"id": "1dc3311d-2235-40d6-88d2-de2bd63e087b"}]'
        or content @> '[{"id": "ammatillinen_perustutkinto_urheilijana"}]'
        or content @> '[{"id": "4fe08958-c0b7-4847-8826-e42503caa662"}]'
        or content @> '[{"id": "32b8440f-d6f0-4a8b-8f67-873344cc3488"}]'
        or content @> '[{"id": "lukio_opinnot_ammatillisen_perustutkinnon_ohella"}]'
        or content @> '[{"id": "ammatilliset_opinnot_lukio_opintojen_ohella"}]'
    order by id asc, versio_id asc, muokattu desc
),

hakukohde as (
    select * from {{ ref('int_hakukohderyhma_hakukohde') }}
),

kysymys as (
    select
        lomake_id,
        jsonb_array_elements(content) as tiedot
    from source
),

hakukohderyhma as (
    select
        lomake_id,
        tiedot ->> 'id' as kysymys_id,
        jsonb_array_elements_text(tiedot -> 'belongs-to-hakukohderyhma') as hakukohderyhma_oid
    from kysymys
    where
        tiedot ->> 'id' in
        (
            '1dc3311d-2235-40d6-88d2-de2bd63e087b',
            'ammatillinen_perustutkinto_urheilijana',
            '4fe08958-c0b7-4847-8826-e42503caa662',
            '32b8440f-d6f0-4a8b-8f67-873344cc3488',
            'lukio_opinnot_ammatillisen_perustutkinnon_ohella',
            'ammatilliset_opinnot_lukio_opintojen_ohella'
        )
),

final as (
    select
        ryhm.lomake_id,
        ryhm.kysymys_id,
        hako.hakukohde_oid
    from hakukohderyhma as ryhm
    left join hakukohde as hako on ryhm.hakukohderyhma_oid = hako.hakukohderyhma_oid

)

select * from final
