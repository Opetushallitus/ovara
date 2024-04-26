{{
  config(
    indexes=[{'columns': ['hakemus_oid','tunniste']}],
    materialized='incremental',
    unique_key='hakemus_oid'
)
}}

with raw as (
    select
        *,
        row_number() over (partition by hakemus_oid order by dw_metadata_timestamp desc) as _row_nr
    from {{ ref('dw_valintapiste_service_pistetieto') }}
    {% if is_incremental() %}
        where dw_metadata_dw_stored_at > coalesce((select max(muokattu) from {{ this }}), '1900-01-01')
    {% endif %}
),

int as (
    select -- noqa: ST06
        hakemus_oid,
        jsonb_array_elements(pisteet) as pisteet,
        dw_metadata_dw_stored_at as muokattu
    from raw
    where _row_nr = 1
),

final as (
    select -- noqa: ST06
        hakemus_oid,
        pisteet ->> 'arvo'::varchar as arvo,
        pisteet ->> 'tunniste'::varchar as tunniste,
        pisteet ->> 'osallistuminen'::varchar as osallistuminen,
        pisteet ->> 'tallettaja'::varchar as tallettaja,
        muokattu
    from int
)

select * from final
