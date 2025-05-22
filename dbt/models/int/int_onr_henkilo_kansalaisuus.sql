{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_oid']}
    ]
    )
}}

with source as (
    select
        henkilo_oid,
        kansalaisuus,
        dw_metadata_stg_stored_at as ladattu
    from {{ ref('int_onr_henkilo') }}
),

raw as (
    select
        henkilo_oid,
        jsonb_array_elements_text(kansalaisuus) as kansalaisuus,
        ladattu
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['henkilo_oid','kansalaisuus']) }} as kansalaisuus_id,
        henkilo_oid,
        kansalaisuus,
        ladattu
    from raw
)

select * from final
