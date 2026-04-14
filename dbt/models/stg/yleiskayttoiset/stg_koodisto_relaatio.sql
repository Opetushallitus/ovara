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
            data.alakoodiuri,
            data.alakoodiversio,
            data.relaatiotyyppi,
            data.relaatioversio,
            data.ylakoodiuri,
            data.ylakoodiversio,
            sorc.dw_metadata_source_timestamp_at as muokattu,
            {{ metadata_columns() }}
        from source as sorc
        cross join lateral json_to_record(data) as data (
            alakoodiuri text,
            alakoodiversio int,
            relaatiotyyppi text,
            relaatioversio int,
            ylakoodiuri text,
            ylakoodiversio int
        )
    ),

    final as (
        select
            {{ dbt_utils.generate_surrogate_key([
            'alakoodiuri',
            'alakoodiversio',
            'relaatiotyyppi',
            'relaatioversio',
            'ylakoodiuri',
            'ylakoodiversio'
            ]) }} as koodirelaatio_id,
            *
        from int
    )

    select * from final
{% endif %}
