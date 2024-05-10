with raw as (
    select
        oid as hakemus_oid,
        hakukohde,
        tiedot,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

sora_terveys as (
    select
        raw.hakemus_oid,
        split_part(tied.key, '_', 2) as hakukohde_oid,
        tied.value as sora_terveys
    from raw,
        jsonb_each_text(raw.tiedot) as tied
    where
        (tied.key like '6a5e1a0f-f47e-479e-884a-765b85bd438c_%' or tied.key like 'sora-terveys%')
        and raw.row_nr = 1
),

sora_aiempi as (
    select
        raw.hakemus_oid,
        split_part(tied.key, '_', 2) as hakukohde_oid,
        tied.value as sora_aiempi
    from raw,
        jsonb_each_text(raw.tiedot) as tied
    where
        (tied.key like '66a6855f-d807-4331-98ea-f14098281fc1_%' or tied.key like 'sora-aiempi%')
        and raw.row_nr = 1
),

hakutoive as (
    select
        hakemus_oid,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid
    from raw
)

select
    hato.hakemus_oid,
    hato.hakukohde_oid,
    sote.sora_terveys,
    soai.sora_aiempi,
    current_timestamp::timestamptz as muokattu
from hakutoive as hato
inner join sora_terveys as sote
    on
        hato.hakukohde_oid = sote.hakukohde_oid
        and hato.hakemus_oid = sote.hakemus_oid
inner join sora_aiempi as soai
    on
        hato.hakukohde_oid = soai.hakukohde_oid
        and hato.hakemus_oid = soai.hakemus_oid
