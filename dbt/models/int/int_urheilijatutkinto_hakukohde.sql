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
            '1dc3311d-2235-40d6-88d2-de2bd63e087b',
            'ammatillinen_perustutkinto_urheilijana'
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
        case
    	    when keys in ('ammatillinen_perustutkinto_urheilijana') then keys
	        else key_hakukohde
        end as hakukohde_oid,
		case
	        when keys in ('ammatillinen_perustutkinto_urheilijana') then null
       		else key_avain
       	end as kysymys_id,
        tiedot ->> keys as arvo
    from raw
   join lateral (
   		select (regexp_match(keys, '1\.2\.246\.562.*'))[1]::text as key_hakukohde) as key_hakukohde on true
   	join lateral (
   		select (regexp_match(keys, '.*(?=_1\.2\.246)'))[1]::text as key_avain ) as key_avain on true
    where
        (
            keys like '1dc3311d-2235-40d6-88d2-de2bd63e087b%'
            or keys like 'ammatillinen_perustutkinto_urheilijana%'
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
            '1dc3311d-2235-40d6-88d2-de2bd63e087b',
            'ammatillinen_perustutkinto_urheilijana'
    	)
),

final as (
    select
    	hakemus_oid,
    	hakukohde_oid,
        case
            when kysymys_id = '1dc3311d-2235-40d6-88d2-de2bd63e087b' and arvo = '0' then true
            when kysymys_id = '1dc3311d-2235-40d6-88d2-de2bd63e087b' and arvo = '1' then false
            when kysymys_id = 'ammatillinen_perustutkinto_urheilijana' and arvo = '0' then true
            when kysymys_id = 'ammatillinen_perustutkinto_urheilijana' and arvo = '1' then false
       end as urheilijatutkinto_kiinnostaa
    from int
)

select
    {{ hakutoive_id() }},
    *
from final
