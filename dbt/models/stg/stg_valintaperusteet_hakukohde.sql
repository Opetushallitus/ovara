with source as (
    select * from {{ source('ovara', 'valintaperusteet_hakukohde') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

final as (
    select
        data -> 'valinnanVaihe' ->> 'valinnanVaiheOid'::varchar as valinnanvaihe_id,
        data ->> 'hakukohdeOid'::varchar as hakukohde_oid,
        data ->> 'hakuOid'::varchar as haku_oid,
        data ->> 'tarjoajaOid'::varchar as tarjoaja_oid,
        (data ->> 'viimeinenValinnanvaihe')::int as viimeinenValinnanvaihe,
        (data -> 'hakukohteenValintaperuste')::jsonb as hakukohteenValintaperuste,
        data -> 'valinnanVaihe' ->> 'nimi'::varchar as valinnanvaihe_nimi,
        (data -> 'valinnanVaihe' ->> 'valinnanVaiheJarjestysluku')::int as valinnanvaihe_jarjestysluku,
        data -> 'valinnanVaihe' ->> 'valinnanVaiheTyyppi'::varchar as valinnanVaiheTyyppi,
        (data -> 'valinnanVaihe' ->> 'valintatapajono')::jsonb as valintatapajono,
        (data -> 'valinnanVaihe' ->> 'valintakoe')::jsonb as valintakoe,
        (data -> 'valinnanVaihe' ->> 'jonot')::jsonb as jonot,
        (data -> 'valinnanVaihe' ->> 'aktiivinen')::boolean as aktiivinen,
        dw_metadata_source_timestamp_at as muokattu,
        {{ metadata_columns() }}
    from source

)

select * from final
