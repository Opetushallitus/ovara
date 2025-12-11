with hakutoive as (
    select
        hakutoive_id,
        hakukohde_henkilo_id,
        hakemus_oid,
        henkilo_oid,
        hakukohde_oid
    from {{ ref('int_ataru_hakutoive') }}
    where not poistettu
),

sora as (
    select
        hakutoive_id,
        sora_terveys,
        sora_aiempi
    from {{ ref('int_ataru_soratietoja') }}
),

harkinnanvaraisuus as (
    select * from {{ ref('int_sure_harkinnanvaraisuus') }}
),

toinen_aste as (
    select hake.hakemus_oid
    from {{ ref('int_ataru_hakemus') }} as hake
    inner join {{ ref('int_kouta_haku') }} as haku on hake.haku_oid = haku.haku_oid
    where haku.haun_tyyppi = 'toinen_aste'
),

kaksoistutkinto as (
    select * from {{ ref('int_kaksoistutkinto_hakukohde') }}
    where not poistettu
),

urheilijatutkinto as (
    select * from {{ ref('int_urheilijatutkinto_hakukohde') }}
),

ilmoittautuminen as (
    select
        hakukohde_henkilo_id,
        tila
    from {{ ref('int_valintarekisteri_ilmoittautuminen') }}
),

pohjakoulutus as (
    select * from {{ ref('int_sure_proxysuoritus_pohjakoulutus') }}
),

final as (
    select
        hato.hakutoive_id,
        hato.hakemus_oid,
        hato.hakukohde_oid,
        sora.sora_terveys,
        sora.sora_aiempi,
        hava.harkinnanvaraisuuden_syy,
        ilmo.tila,
        katu.kaksoistutkinto_kiinnostaa,
        urtu.urheilijatutkinto_kiinnostaa,
        poko.pohjakoulutus,
        poko.pohjakoulutus_nimi
    from hakutoive as hato
    left join sora on hato.hakutoive_id = sora.hakutoive_id
    left join harkinnanvaraisuus as hava on hato.hakutoive_id = hava.hakutoive_id
    left join ilmoittautuminen as ilmo on hato.hakukohde_henkilo_id = ilmo.hakukohde_henkilo_id
    left join kaksoistutkinto as katu on hato.hakutoive_id = katu.hakutoive_id
    left join urheilijatutkinto as urtu on hato.hakutoive_id = urtu.hakutoive_id
    left join pohjakoulutus as poko on hato.hakemus_oid = poko.hakemus_oid
)

select final.*
from final
inner join toinen_aste on final.hakemus_oid = toinen_aste.hakemus_oid
