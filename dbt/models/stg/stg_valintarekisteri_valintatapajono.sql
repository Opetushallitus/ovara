with source as (
    select * from {{ source('ovara', 'valintarekisteri_valintatapajono') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

raw as (
    select
        data ->> 'oid' as oid,
        data ->> 'hakukohdeOid' as hakukohde_oid,
        (data ->> 'alinHyvaksyttyPistemaara')::float as alinHyvaksyttyPistemaara,
        (data ->> 'alkuperaisetAloituspaikat')::int as alkuperaisetAloituspaikat,
        (data ->> 'aloituspaikat')::int as Aloituspaikat,
        (data ->> 'eiVarasijatayttoa')::boolean as eiVarasijatayttoa,
        (data ->> 'hakeneet')::int as hakeneet,
        (data ->> 'kaikkiEhdonTayttavatHyvaksytaan')::boolean as kaikkiEhdonTayttavatHyvaksytaan,
        data ->> 'nimi' as nimi,
        (data ->> 'poissaOlevaTaytto')::boolean as poissaOlevaTaytto,
        (data ->> 'prioriteetti')::int as prioriteetti,
        (data ->> 'sijoiteltuIlmanVarasijasaantojaNiidenOllessaVoimassa')::boolean as sijoiteltuIlmanVarasijasaantojaNiidenOllessaVoimassa,
        data ->> 'tasasijasaanto' as tasasijasaanto,
        (data ->> 'valintaesitysHyvaksytty')::boolean as valintaesitysHyvaksytty,
        (data ->> 'varasijanTayttoPaivat')::int as varasijanTayttoPaivat,
        (data ->> 'varasijat')::int as varasijat,
        (data ->> 'varasijojaKaytetaanAsti')::timestamptz as varasijojaKaytetaanAsti,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key (['oid','hakukohde_oid']) }} as valintatapajono_id,
        *
    from raw
)

select * from final
