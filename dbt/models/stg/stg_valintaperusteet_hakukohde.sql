with source as (
    select * from {{ source('ovara', 'valintaperusteet_hakukohde') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        coalesce(data -> 'valinnanVaihe' ->> 'valinnanVaiheOid'::varchar,'puuttuu') as valinnanvaihe_id,
        data ->> 'hakukohdeOid'::varchar as hakukohde_oid,
        data ->> 'hakuOid'::varchar as haku_oid,
        data ->> 'tarjoajaOid'::varchar as tarjoaja_oid,
        data -> 'valinnanVaihe' ->> 'nimi'::varchar as valinnanvaihe_nimi,
        (data -> 'valinnanVaihe' ->> 'valinnanVaiheJarjestysluku')::int as valinnanvaihe_jarjestysluku,
        (data ->> 'viimeinenValinnanvaihe')::int as viimeinenValinnanvaihe,
        (data -> 'valinnanVaihe' ->> 'aktiivinen')::boolean as aktiivinen,
        data -> 'valinnanVaihe' ->> 'valinnanVaiheTyyppi'::varchar as valinnanvaihe_tyyppi,
        (data -> 'hakukohteenValintaperuste')::jsonb as hakukohteenValintaperuste,
        (data -> 'valinnanVaihe' -> 'valintatapajono')::jsonb as valintatapajono,
        (data -> 'valinnanVaihe' -> 'valintakoe')::jsonb as valintakoe,
        (data -> 'valinnanVaihe' ->> 'jonot')::jsonb as jonot,
        dw_metadata_source_timestamp_at as muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
