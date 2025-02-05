{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['muokattu']}
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'onr_henkilo') }}
    {#
    is_incremental is never true because of config materialized=table
    this table is being truncated whenever a new file is processed
    #}
    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
    {# end of incremental logic #}
),

final as (
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'master_oid'::varchar as master_oid,
        data ->> 'etunimet'::varchar as etunimet,
        data ->> 'sukunimi'::varchar as sukunimi,
        data ->> 'hetu'::varchar as hetu,
        (data ->> 'syntymaaika')::date as syntymaaika,
        data ->> 'aidinkieli' as aidinkieli,
        array_to_json(string_to_array((data ->> 'kansalaisuus')::varchar, ','))::jsonb as kansalaisuus,
        (data ->> 'sukupuoli')::int as sukupuoli,
        (data ->> 'turvakielto')::boolean = 't' as turvakielto,
        (data ->> 'yksiloityvtj')::boolean = 't' as yksiloityvtj,
        (data ->> 'created')::timestamptz as luotu,
        (data ->> 'updated')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
