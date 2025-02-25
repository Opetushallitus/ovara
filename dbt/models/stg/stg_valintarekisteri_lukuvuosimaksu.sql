with raw as (
    select * from {{ source('ovara', 'valintarekisteri_lukuvuosimaksu') }}
),

final as (
    select
        data ->> 'hakukohdeOid' as hakukohde_oid,
        data ->> 'personOid' as henkilo_oid,
        data ->> 'maksuntila' as maksun_tila,
        data ->> 'muokkaaja' as muokkaaja,
        (data ->> 'luotu')::timestamptz as muokattu,
        (data ->> 'systemTime')::timestamptz as luontihetki,
        {{ metadata_columns() }}
    from raw
)

select
    {{ hakukohde_henkilo_id() }},
    *
from final
