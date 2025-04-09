{{
  config(
    materialized = 'table',
    )
}}

with hakutoive as (
    select * from {{ ref('int_ataru_hakutoive') }}
    where not poistettu
),

julkaistu as (
    select * from {{ ref('int_valintarekisteri_hyvaksyttyjulkaistuhakutoive') }}
),

hakemus as (
    select * from {{ ref('int_ataru_hakemus') }}
),

haku as (
    select * from {{ ref('int_haku') }}
),

vastaanotto as (
    select * from {{ ref('int_valintarekisteri_vastaanotto') }}
),

valinnat as (
    select * from {{ ref('int_valinta') }}
),

harkinnanvaraisuus as (
    select * from {{ ref('int_sure_harkinnanvaraisuus') }}
),

ilmoittautuminen as (
    select * from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

ensikertalainen as (
    select * from {{ ref('int_sure_ensikertalainen') }}
),

int as (
    select
        hato.hakutoive_id,
        hato.hakukohde_henkilo_id,
        hato.hakemus_oid,
        hake.haku_oid,
        hato.henkilo_oid,
        hato.hakukohde_oid,
        case
            when haku.jarjestetyt_hakutoiveet then hato.hakutoivenumero
            else -1
        end as hakutoivenumero,
        julk.hyvaksyttyjajulkaistu,
        haku.vastaanotto_paattyy,
        haku.hakijakohtainen_paikan_vastaanottoaika,
        date_trunc(
            'minute', greatest(
                haku.vastaanotto_paattyy,
                (
                    julk.hyvaksyttyjajulkaistu + (interval '1' day * haku.hakijakohtainen_paikan_vastaanottoaika::int)
                )::timestamptz
            )
        )
        as viimeinen_vastaanottopaiva,
        vaot.vastaanottotieto,
        ilmo.tila as ilmoittautumisen_tila,
        vali.valintatapajonot,
        vali.valintatieto,
        vali.ehdollisesti_hyvaksytty,
        vali.valintatiedon_pvm,
        hava.harkinnanvaraisuuden_syy,
        enke.isensikertalainen as ensikertalainen
    from hakutoive as hato
    left join julkaistu as julk on hato.hakukohde_henkilo_id = julk.hakukohde_henkilo_id
    left join hakemus as hake on hato.hakemus_oid = hake.hakemus_oid
    left join haku on hake.haku_oid = haku.haku_oid
    left join vastaanotto as vaot on hato.hakukohde_henkilo_id = vaot.hakukohde_henkilo_id
    left join valinnat as vali on hato.hakutoive_id = vali.hakutoive_id
    left join harkinnanvaraisuus as hava on hato.hakutoive_id = hava.hakutoive_id
    left join ilmoittautuminen as ilmo on hato.hakukohde_henkilo_id = ilmo.hakukohde_henkilo_id
    left join ensikertalainen as enke on hake.haku_oid = enke.haku_oid and hake.henkilo_oid = enke.henkilo_oid
),

final as (
    select
        hakutoive_id,
        hakukohde_henkilo_id,
        {{ dbt_utils.generate_surrogate_key(['henkilo_oid', 'hakemus_oid']) }} as henkilo_hakemus_id,
        hakemus_oid,
        haku_oid,
        henkilo_oid,
        hakukohde_oid,
        hakutoivenumero,
        make_timestamptz(
            date_part('year', viimeinen_vastaanottopaiva)::int,
            date_part('month', viimeinen_vastaanottopaiva)::int,
            date_part('day', viimeinen_vastaanottopaiva)::int,
            date_part('hour', vastaanotto_paattyy)::int,
            date_part('minute', vastaanotto_paattyy)::int,
            0
        )
        + interval '1' day * (
            case when vastaanotto_paattyy::time - viimeinen_vastaanottopaiva::time < '0:00:00'::time then 1 else 0 end
        ) as viimeinen_vastaanottopaiva,
        vastaanottotieto,
        ilmoittautumisen_tila,
        valintatapajonot,
        valintatieto,
        ehdollisesti_hyvaksytty,
        valintatiedon_pvm,
        harkinnanvaraisuuden_syy,
        ensikertalainen
    from int
)

select * from final
