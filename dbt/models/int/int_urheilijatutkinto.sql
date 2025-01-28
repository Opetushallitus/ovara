{{
  config(
    indexes = [
        {'columns': ['hakemus_oid']}
    ]
    )
}}

with raw as ( --noqa: PRS
    select
        hakemus_oid,
        jsonb_object_keys(tiedot) as keys,
        tiedot
from {{ ref('int_ataru_hakemus') }}
),

rows as (
    select * from raw where
    keys = '1dc3311d-2235-40d6-88d2-de2bd63e087b_%'
)

select
    hakemus_oid,
    split_part(keys,'_',2) as hakukohde,
    (tiedot ->> keys)::boolean as tutkinto_urheilijana_kiinnostaa
from rows
