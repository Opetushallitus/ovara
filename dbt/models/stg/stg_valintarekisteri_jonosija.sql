with source as (
    select * from {{ source('ovara', 'valintarekisteri_jonosija') }}
),

final as (
    select
        data ->> 'hakemusOid' as hakemus_oid,
        data ->> 'hakukohdeOid' as hakukohde_oid,
        data ->> 'valintatapajonoOid' as valintatapajono_oid,
        (data ->> 'hyvaksyttyHarkinnanvaraisesti')::boolean as hyvaksytty_harkinnanvaraisesti,
        (data ->> 'jonosija')::int as jonosija,
        (data ->> 'varasijanNumero')::int as varasijan_numero,
        (data ->> 'onkoMuuttunutViimeSijoittelussa')::boolean as onko_muuttunut_viime_sijoittelussa,
        (data ->> 'prioriteetti')::int as prioriteetti,
        (data ->> 'pisteet')::float as pisteet,
        (data ->> 'siirtynytToisestaValintatapajonosta')::boolean as siirtynyt_toisesta_valintatapajonosta,
        data ->> 'sijoitteluajoId' as sijoitteluajo_id,
        (data ->> 'systemTime')::timestamptz as muokattu,
        (data ->> 'tasasijaJonosija')::int as tasasija_jonosija,
        data ->> 'tila' as tila,
        {{ metadata_columns() }}
    from source
)

select
    {{ dbt_utils.generate_surrogate_key(
        ['hakemus_oid','hakukohde_oid','valintatapajono_oid']
        ) }} as id,
    *
from final
