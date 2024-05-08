with raw as (
    select
        oid as hakemus_oid,
        versio_id,
        hakukohde,
        tiedot
    from {{ ref('dw_ataru_hakemus') }}
    {% if is_incremental() %}
       where dw_metadata_dw_stored_at > (select max(muokattu) from {{ this }})
    {% endif %}
),

sora_terveys as (
	select
		hakemus_oid,
        versio_id,
		split_part(key,'_',2) as hakukohde_oid,
		value as sora_terveys
	from raw,
	jsonb_each_text(tiedot)
	where key like '6a5e1a0f-f47e-479e-884a-765b85bd438c_%' or key like 'sora-terveys%'
),

sora_aiempi as (
	select
		hakemus_oid,
        versio_id,
		split_part(key,'_',2) as hakukohde_oid,
		value as sora_aiempi
	from raw,
	jsonb_each_text(tiedot)
	where key like '66a6855f-d807-4331-98ea-f14098281fc1_%' or key like 'sora-aiempi%'
),

hakutoive as (
    select
        hakemus_oid,
        versio_id,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid
    from raw
)

select
    hato.hakemus_oid,
    hato.versio_id,
    hato.hakukohde_oid,
    sote.sora_terveys,
    soai.sora_aiempi,
    current_timestamp::timestamptz as muokattu
from hakutoive hato
join sora_terveys sote on hato.hakukohde_oid=sote.hakukohde_oid and hato.hakemus_oid=sote.hakemus_oid and hato.versio_id=sote.versio_id
join sora_aiempi soai on hato.hakukohde_oid=soai.hakukohde_oid and hato.hakemus_oid=soai.hakemus_oid and hato.versio_id=soai.versio_id


