with raw as (
    select
        content,
        row_number() over (partition by id order by versio_id desc, muokattu desc) as rownr
    from {{ ref('dw_ataru_lomake') }}
    where
        content @> '[{"id": "1dc3311d-2235-40d6-88d2-de2bd63e087b"}]'
        or content @> '[{"id": "ammatillinen_perustutkinto_urheilijana"}]'

),

hakukohderyhma_hakukohde as (
    select * from {{ ref('int_hakukohderyhma_hakukohde') }}
),

tiedot as (
    select jsonb_array_elements(content) as tiedot
    from raw where rownr = 1
),

hakukohderyhmat as (
    select jsonb_array_elements_text(tiedot -> 'belongs-to-hakukohderyhma') as hakukohderyhma_oid
    from tiedot
    where tiedot ->> 'id' in ('1dc3311d-2235-40d6-88d2-de2bd63e087b', 'ammatillinen_perustutkinto_urheilijana')
)

select distinct haha.hakukohde_oid
from hakukohderyhma_hakukohde as haha
inner join hakukohderyhmat as hary on haha.hakukohderyhma_oid = hary.hakukohderyhma_oid
