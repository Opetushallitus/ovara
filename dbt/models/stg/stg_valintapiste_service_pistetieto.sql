{{
  config(
    indexes = [
        {'columns': ['dw_metadata_dbt_copied_at']},
        {'columns': ['dw_metadata_stg_stored_at']},
        {'columns': ['valintakoe_hakemus_id']},
        {'columns': ['hakemus_oid']},
        {'columns': ['valintakoe_tunniste']}
    ]
    )
}}

with source as ( --noqa: PRS
    select * from {{ source('ovara', 'valintapiste_service_pistetieto') }}

    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

rows as (
    select
        data ->> 'hakemusOID'::varchar as hakemus_oid,
        json_array_elements (data -> 'pisteet')::jsonb as pisteet,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        hakemus_oid,
        pisteet ->> 'tunniste' as valintakoe_tunniste,
        pisteet ->> 'arvo' as arvo,
        pisteet ->> 'osallistuminen' as osallistuminen,
        pisteet ->> 'tallettaja' as tallettaja,
        (pisteet ->> 'poistettu')::boolean as poistettu,
        coalesce ((pisteet ->> 'last_modified')::timestamptz, current_timestamp::timestamptz) as muokattu,
        {{ metadata_columns() }}
    from rows
)

select
    {{ dbt_utils.generate_surrogate_key (['hakemus_oid','valintakoe_tunniste']) }} as valintakoe_hakemus_id,
    *
from final
