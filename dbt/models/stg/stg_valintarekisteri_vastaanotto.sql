with source as (
    select * from {{ source('ovara', 'valintarekisteri_vastaanotto') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

raw as (
    select
        data ->> 'hakukohdeOid' as hakukohde_oid,
        data ->> 'henkiloOid' as henkilo_oid,
        data ->> 'ilmoittaja' as ilmoittaja,
        data ->> 'selite' as selite,
        data ->> 'action' as operaatio,
        (data ->> 'id')::int as id,
        (data ->> 'timestamp')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key (['hakukohde_oid','henkilo_oid']) }}
        as vastaanotto_id,
        *
    from raw
)

select * from final
