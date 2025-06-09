{{
  config(
    materialized = 'incremental',
    unique_key = 'hakutoive_id',
    incremental_strategy='merge',
    indexes = [
        {'columns':['hakutoive_id']},
        {'columns':['dw_metadata_dw_stored_at']}
    ]
    )
}}

with raw as (
    select
        hakemus_oid,
        hakukohde,
        tiedot,
        dw_metadata_dw_stored_at
    from {{ ref('int_ataru_hakemus') }}
    where
        tiedot ?| array[
            '66a6855f-d807-4331-98ea-f14098281fc1',
            '6a5e1a0f-f47e-479e-884a-765b85bd438c',
            'sora-terveys',
            'sora-aiempi'
        ]
    {% if is_incremental() %}
            and dw_metadata_dw_stored_at > (select max(dw_metadata_dw_stored_at) from {{ this }})
    {% endif %}
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
),

hakutoive as (
    select
        hakemus_oid,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid,
        dw_metadata_dw_stored_at
    from raw
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
                'hato.hakemus_oid',
                'hato.hakukohde_oid'
         ]) }}
        as hakutoive_id,
        hato.hakemus_oid,
        hato.hakukohde_oid,
        coalesce(sote.sora_terveys, '0') = '1' as sora_terveys,
        coalesce(soai.sora_aiempi, '0') = '1' as sora_aiempi,
        hato.dw_metadata_dw_stored_at
    from hakutoive as hato
    inner join sora_terveys as sote
        on
            hato.hakukohde_oid = sote.hakukohde_oid
            and hato.hakemus_oid = sote.hakemus_oid
    inner join sora_aiempi as soai
        on
            hato.hakukohde_oid = soai.hakukohde_oid
            and hato.hakemus_oid = soai.hakemus_oid
)

select * from final
