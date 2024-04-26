with source as (
      select * from {{ source('ovara', 'koodisto_relaatio') }}
 
      {% if is_incremental() %}

       where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }}) 

    {% endif %}
),

int as 
(   
    select 
        data ->> 'alakoodiuri'::varchar as alakoodiuri,
        (data ->> 'alakoodiversio')::int as alakoodiversio,
        data ->> 'relaatiotyyppi'::varchar as relaatiotyyppi,
        (data ->> 'relaatioversio')::int as relaatioversio,
        data ->> 'ylakoodiuri'::varchar as ylakoodiuri,
        (data ->> 'ylakoodiversio')::int as ylakoodiversio,
        dw_metadata_source_timestamp_at as muokattu,
        {{ metadata_columns() }}

        from source

),

final as 
(
    select
    {{ dbt_utils.generate_surrogate_key([
        'alakoodiuri',
        'alakoodiversio',
        'relaatiotyyppi',
        'relaatioversio',
        'ylakoodiuri',
        'ylakoodiuri'
        ]) }} as id,
    * from int
)

select * from final