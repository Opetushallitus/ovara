{{
  config(
    materialized = 'table',
    )
}}

with hakutoive as (
    select * from {{ ref('int_ataru_hakutoive') }} where not poistettu
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

int as (
    select
        hato.hakutoive_id,
        hato.hakukohde_henkilo_id,
        hato.hakemus_oid,
        hato.henkilo_oid,
        hato.hakukohde_oid,
        hato.hakutoivenumero,
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
        vali.valintatapajonot,
        hava.harkinnanvaraisuuden_syy
    from hakutoive as hato
    left join julkaistu as julk on hato.hakukohde_henkilo_id = julk.hakukohde_henkilo_id
    left join hakemus as hake on hato.hakemus_oid = hake.hakemus_oid
    left join haku on hake.haku_oid = haku.haku_oid
    left join vastaanotto as vaot on hato.hakukohde_henkilo_id = vaot.hakukohde_henkilo_id
    left join valinnat as vali on hato.hakutoive_id = vali.hakutoive_id
    left join harkinnanvaraisuus as hava on hato.hakutoive_id = hava.hakutoive_id
),

final as (
    select
        hakutoive_id,
        hakukohde_henkilo_id,
        hakemus_oid,
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
        valintatapajonot,
        harkinnanvaraisuuden_syy
    from int
)

select * from final
