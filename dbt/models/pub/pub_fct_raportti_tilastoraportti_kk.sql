{{
  config(
    enabled=true
    )
}}

with hakukohde as (
    select hako.*
    from {{ ref('int_kouta_hakukohde') }} as hako
    inner join {{ ref('int_kouta_haku') }} as haku on hako.haku_oid=haku.haku_oid and haku.haun_tyyppi = 'korkeakoulu'
),

toteutus as (
    select * from {{ ref('int_kouta_toteutus') }}
),

koulutus as (
    select * from {{ ref('int_kouta_koulutus') }}
),

koulutustiedot as (
    select * from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
),

final as (
    select
        hako.hakukohde_oid,
        koti.alempi_kk_aste::boolean,
	      koti.ylempi_kk_aste::boolean,
	      koti.okmohjauksenala
    from hakukohde as hako
    inner join toteutus as tote on hako.toteutus_oid = tote.toteutus_oid
    inner join koulutus as koul on tote.koulutus_oid = koul.koulutus_oid
    inner join koulutustiedot as koti on koul.koulutuksetkoodiuri ? koti.versioitu_koodiuri
)

select * from final
