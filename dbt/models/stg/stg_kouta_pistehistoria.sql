with source as ( --noqa: PRS
    select * from {{ source('ovara', 'kouta_pistehistoria') }}

    {%- if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }} )
    {% endif -%}
),

rows as (
    select
        data ->> 'tarjoaja'::varchar as tarjoaja,
        data ->> 'hakukohdekoodi'::varchar as hakukohdekoodi,
        (data ->> 'pisteet')::float as pisteet,
        (data ->> 'vuosi')::int as vuosi,
        data ->> 'valintatapajonoOid'::varchar as valintatapajonoOid,
        data ->> 'hakukohdeOid'::varchar as hakukohdeOid,
        data ->> 'hakuOid'::varchar as hakuOid,
        data ->> 'valintatapajonoTyyppi'::varchar as valintatapajonoTyyppi,
        (data ->> 'aloituspaikat')::int as aloituspaikat,
        (data->> 'ensisijaisestiHakeneet')::int as ensisijaisestiHakeneet,
        {{ muokattu_column() }},
        {{ metadata_columns() }}
    from source
),

final as
(
    select
    {{ dbt_utils.generate_surrogate_key(['tarjoaja','hakukohdekoodi','vuosi']) }} as id,
    *
    from rows
)

select * from final
