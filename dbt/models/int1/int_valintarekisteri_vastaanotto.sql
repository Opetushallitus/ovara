with source as (
    select distinct on (hakukohde_henkilo_id) * from {{ ref('dw_valintarekisteri_vastaanotto') }}
    where poistettu_aikaleima is null
    order by hakukohde_henkilo_id asc, muokattu desc
)

select * from source
