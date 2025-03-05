--{{ ref('pub_dim_hakukohde') }}
--{{ ref('pub_fct_hakemus') }}
{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['hakukohde_oid']},
        {'columns':['henkilo_hakemus_id']},
        {'columns':['haku_oid']},
    ]
    )
}}

with hakutoive as not materialized (
    select * from {{ ref('int_hakutoive') }}
),

final as (
    select
        hakutoive_id,
        hakukohde_henkilo_id,
        henkilo_hakemus_id,
        hakemus_oid,
        haku_oid,
        henkilo_oid,
        hakukohde_oid,
        hakutoivenumero,
        viimeinen_vastaanottopaiva,
        vastaanottotieto,
        ilmoittautumisen_tila,
        valintatapajonot,
        valintatieto,
        valintatiedon_pvm,
        harkinnanvaraisuuden_syy,
        ensikertalainen
    from hakutoive
)

select * from final
