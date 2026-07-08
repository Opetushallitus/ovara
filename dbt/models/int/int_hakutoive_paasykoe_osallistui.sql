{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('hakutoive_id') }}"
    ]
    )
}}
with pistetieto as (
    select
        hakemus_oid,
        valintakoe_tunniste,
        osallistuminen
        from {{ ref('int_valintalaskenta_pistetieto') }}
),

valintaperuste as (
    select
        hakukohde_oid,
        tunniste,
        tyyppi
    from {{ ref('int_hakukohde_valintaperuste') }}
),

osallistui as (
    select
        hakemus_oid,
        valintakoe_tunniste,
        bool_or(osallistuminen = 'OSALLISTUI') as osallistui
    from pistetieto
    group by
        hakemus_oid,
        valintakoe_tunniste
),

final as (
    select
        osal.hakemus_oid,
        vape.hakukohde_oid,
        bool_or(
            vape.tyyppi = 'syotettavanarvontyypit_valintakoe'
            and osal.osallistui
        ) as osallistui_paasykoe,
        bool_or(
            vape.tyyppi = 'syotettavanarvontyypit_muu'
            and osal.osallistui
        ) as osallistui_lisanaytto
    from osallistui osal
    join valintaperuste vape
        on osal.valintakoe_tunniste = vape.tunniste
    group by
        osal.hakemus_oid,
        vape.hakukohde_oid
)

select
    {{ hakutoive_id() }},
    *
from final