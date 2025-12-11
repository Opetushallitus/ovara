{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['koodirelaatio_id']},
    ]
    )
}}

{% if is_loading('koodisto_relaatio') %}
select * from {{ this }}
{% else %}

    with source as (
        select * from {{ source('ovara', 'koodisto_relaatio') }}

    ),

    int as (
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

    final as (
        select
            {{ dbt_utils.generate_surrogate_key([
            'alakoodiuri',
            'alakoodiversio',
            'relaatiotyyppi',
            'relaatioversio',
            'ylakoodiuri',
            'ylakoodiuri'
            ]) }} as koodirelaatio_id,
            *
        from int
    )

    select * from final
{% endif %}
