{{
  config(
    indexes = [
        {'columns': ['hakutoive_id','poistettu']},
        {'columns':['dw_metadata_dw_stored_at']}
    ],
    materialized = 'incremental',
    unique_key = 'hakutoive_id',
    incremental_strategy = 'merge',
    pre_hook = "
    {% if is_incremental() %}
        UPDATE {{ this }} AS h
        SET poistettu = true
        FROM {{ ref('int_ataru_hakemus') }} AS a
        JOIN (
            SELECT MAX(dw_metadata_dw_stored_at) AS max_dw
            FROM {{ this }}
        ) AS m ON true
        WHERE h.hakemus_oid = a.hakemus_oid
        AND a.dw_metadata_dw_stored_at > m.max_dw;
    {% endif %}
"
    )
}}

with max_timestamp as (
	select max(dw_metadata_dw_stored_at) as max_timestamp from {{ this }}
),

raw as ( --noqa: PRS
    select
        hakemus_oid,
        lomake_id,
        hakukohde,
        jsonb_object_keys(tiedot) as keys,
        tiedot,
        dw_metadata_dw_stored_at
    from {{ ref('int_ataru_hakemus') }}
    cross join max_timestamp
    where
        tiedot ?| array[
            '4fe08958-c0b7-4847-8826-e42503caa662',
            '32b8440f-d6f0-4a8b-8f67-873344cc3488',
            'lukio_opinnot_ammatillisen_perustutkinnon_ohella',
            'ammatilliset_opinnot_lukio_opintojen_ohella-amm'
        ]
    {% if is_incremental() %}
    and dw_metadata_dw_stored_at > max_timestamp
    {% endif %}
),

hakukohde as (
    select * from {{ ref('int_lomake_hakukohde') }}
),

rows as (
    select
        hakemus_oid,
        hakukohde,
        lomake_id,
        dw_metadata_dw_stored_at,
        case
	        when keys in ('lukio_opinnot_ammatillisen_perustutkinnon_ohella', 'ammatilliset_opinnot_lukio_opintojen_ohella-amm') then keys
	        else key_hakukohde
		    end
	    as hakukohde_oid,
		case
	        when keys in ('lukio_opinnot_ammatillisen_perustutkinnon_ohella', 'ammatilliset_opinnot_lukio_opintojen_ohella-amm') then null
       		else key_avain
       	end as kysymys_id,
        tiedot ->> keys as arvo,
        key_avain
    from raw
   join lateral (
   		select (regexp_match(keys, '1\.2\.246\.562.*'))[1]::text as key_hakukohde) as key_hakukohde on true

   	join lateral (
   		select (regexp_match(keys, '.*(?=_1\.2\.246)'))[1]::text as key_avain ) as key_avain on true

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
        coalesce(hako.hakukohde_oid, rows.hakukohde_oid) as hakukohde_oid,
        rows.dw_metadata_dw_stored_at
    from rows
    left join hakukohde as hako on
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
       end as kaksoistutkinto_kiinnostaa,
       dw_metadata_dw_stored_at
    from int
)

select
    {{ hakutoive_id() }},
    *,
    false as poistettu
from final
