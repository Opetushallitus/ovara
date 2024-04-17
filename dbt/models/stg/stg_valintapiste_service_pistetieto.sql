with source as (
      select * from {{ source('ovara', 'valintapiste_service_pistetieto') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

final as 
(
    select 
        data ->> 'hakemusOID'::varchar as hakemus_oid,
        (data -> 'pisteet')::jsonb as pisteet,
        {{ metadata_columns() }}
    from source

)

select * from final
