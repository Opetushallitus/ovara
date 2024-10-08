with source as (
    select * from {{ source('ovara', 'organisaatio_ryhma') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

final as (
    select
        data ->> 'oid' as oid,
        data ->> 'nimiFi' as nimi_fi,
        data ->> 'nimiSv' as nimi_sv,
        data ->> 'nimiEn' as nimi_en,
        {{ metadata_columns() }}
    from source
)

select * from final
