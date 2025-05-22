{{
  config(
    enabled = false
    )
}}
with source as (
    select * from {{ source('ovara', 'valintalaskenta_valintalaskennan_tulos') }}
    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}

),

final as (
    select
        data ->> 'valinnanvaiheoid'::varchar as valinnanvaihe_id,
        data ->> 'hakuOid'::varchar as hakuOid,
        (data ->> 'jarjestysnumero')::int as jarjestysnumero,
        data ->> 'nimi'::varchar as nimi,
        (data ->> 'valinnanvaihe')::int as valinnanvaihe,
        (data -> 'valintakokeet')::json as valintakokeet,
        (data -> 'valintatapajonot')::json as valintatapajonot,
        regexp_replace(data ->> 'createdAt', '[\x202f]+', ' ')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
