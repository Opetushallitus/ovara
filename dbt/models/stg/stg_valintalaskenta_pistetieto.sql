{{
  config(
    indexes = [
        {'columns': ['dw_metadata_dbt_copied_at']}
    ]
    )
}}

with source as ( --noqa: PRS
    select * from {{ source('ovara', 'valintalaskenta_pistetieto') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

final as (
    select
        sorc.data ->> 'hakemusOID'::varchar as hakemus_oid,
        pist.pisteet ->> 'tunniste' as valintakoe_tunniste,
        pist.pisteet ->> 'arvo' as arvo,
        pist.pisteet ->> 'osallistuminen' as osallistuminen,
        pist.pisteet ->> 'tallettaja' as tallettaja,
        (pist.pisteet ->> 'poistettu')::boolean as poistettu,
        coalesce(
            (pist.pisteet ->> 'last_modified')::timestamptz,
            current_timestamp::timestamptz
        ) as muokattu,
        {{ metadata_columns() }}
    from source as sorc
    cross join lateral json_array_elements(sorc.data -> 'pisteet') as pist (pisteet)
)

select
    {{ dbt_utils.generate_surrogate_key (['hakemus_oid','valintakoe_tunniste']) }} as valintakoe_hakemus_id,
    *
from final
