{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid','hakemus_oid']}
    ],
    pre_hook='set enable_mergejoin = off;'
    )
}}

with valinnantulos as not materialized (
    select
        hakukohde_oid,
        valintatapajono_oid,
        hakemus_oid,
        henkilo_oid,
        valinnan_tila,
        ehdollisesti_hyvaksyttavissa,
        ehdollisen_hyvaksymisen_ehto,
        valinnantilan_kuvauksen_teksti,
        julkaistavissa,
        hyvaksyperuuntunut,
        valintatiedon_pvm
    from {{ ref('int_valintarekisteri_valinnantulos') }}
),

jonosija as not materialized (
    select
        hakemus_oid,
        hakukohde_oid,
        valintatapajono_oid,
        hyvaksytty_harkinnanvaraisesti,
        jonosija,
        varasijan_numero,
        onko_muuttunut_viime_sijoittelussa,
        prioriteetti,
        pisteet,
        siirtynyt_toisesta_valintatapajonosta,
        sijoitteluajo_id
    from {{ ref('int_valintarekisteri_jonosija') }}
),

hyvaksytty as not materialized (
    select
        hakukohde_oid,
        henkilo_oid,
        hyvaksyttyjajulkaistu
    from {{ ref('int_valintarekisteri_hyvaksyttyjulkaistuhakutoive') }}
),

lukuvuosimaksu as not materialized (
    select
        hakukohde_oid,
        henkilo_oid,
        maksun_tila
    from {{ ref('int_valintarekisteri_lukuvuosimaksu') }}
),

ilmoittautuminen as not materialized (
    select
        hakukohde_oid,
        henkilo_oid,
        ilmoittaja,
        selite,
        tila
    from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

vastaanotto as not materialized (
    select
        hakukohde_oid,
        henkilo_oid,
        ilmoittaja,
        selite,
        operaatio
    from {{ ref('int_valintarekisteri_vastaanotto') }}
),

final as (
    select
        vatu.hakukohde_oid,
        vatu.valintatapajono_oid,
        vatu.hakemus_oid,
        vatu.henkilo_oid,
        vatu.valinnan_tila,
        vatu.ehdollisesti_hyvaksyttavissa,
        vatu.ehdollisen_hyvaksymisen_ehto ->> 'fi' as ehdollisen_hyvaksymisen_ehto_fi,
        vatu.ehdollisen_hyvaksymisen_ehto ->> 'sv' as ehdollisen_hyvaksymisen_ehto_sv,
        vatu.ehdollisen_hyvaksymisen_ehto ->> 'en' as ehdollisen_hyvaksymisen_ehto_en,
        vatu.valinnantilan_kuvauksen_teksti ->> 'fi' as valinnantila_kuvaus_fi,
        vatu.valinnantilan_kuvauksen_teksti ->> 'sv' as valinnantila_kuvaus_sv,
        vatu.valinnantilan_kuvauksen_teksti ->> 'en' as valinnantila_kuvaus_en,
        vatu.julkaistavissa,
        vatu.hyvaksyperuuntunut,
        vatu.valintatiedon_pvm,
        josi.hyvaksytty_harkinnanvaraisesti,
        josi.jonosija,
        josi.varasijan_numero,
        josi.onko_muuttunut_viime_sijoittelussa,
        josi.prioriteetti,
        josi.pisteet,
        josi.siirtynyt_toisesta_valintatapajonosta,
        josi.sijoitteluajo_id,
        hysa.hyvaksyttyjajulkaistu,
        lvma.maksun_tila,
        ilmo.ilmoittaja as ilmoitus_ilmoittaja,
        ilmo.selite,
        ilmo.tila as ilmoituksen_tila,
        vaot.ilmoittaja as vastaanotto_ilmoittaja,
        vaot.selite as vastaanotto_selite,
        vaot.operaatio as vastaanotto_tila
    from valinnantulos as vatu
    left join jonosija as josi
        on vatu.hakemus_oid = josi.hakemus_oid and vatu.valintatapajono_oid = josi.valintatapajono_oid
    left join hyvaksytty as hysa
        on vatu.henkilo_oid = hysa.henkilo_oid and vatu.hakukohde_oid = hysa.hakukohde_oid
    left join lukuvuosimaksu as lvma
        on vatu.henkilo_oid = lvma.henkilo_oid and vatu.hakukohde_oid = lvma.hakukohde_oid
    left join ilmoittautuminen as ilmo
        on vatu.henkilo_oid = ilmo.henkilo_oid and vatu.hakukohde_oid = ilmo.hakukohde_oid
    left join vastaanotto as vaot
        on vatu.henkilo_oid = vaot.henkilo_oid and vatu.hakukohde_oid = vaot.hakukohde_oid
)

select * from final
