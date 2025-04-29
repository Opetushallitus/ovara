{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    indexes = [
        {'columns': ['henkilo_oid']},
        {'columns': ['muokattu']}
    ]
    )
}}

with source as (
    select * from {{ source('ovara', 'onr_henkilo') }}
    {% if is_incremental() %}
    -- process only rows where updated is newer than newest timestamp in dw
        where
            (data ->> 'updated')::timestamptz > (
                select coalesce(max(muokattu), '1899-12-31') from {{ source('yleiskayttoiset', 'dw_onr_henkilo') }}
            )
    --end of incremental logic #}
    {% endif %}

),

final as (
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'master_oid'::varchar as master_oid,
        data ->> 'etunimet'::varchar as etunimet,
        data ->> 'sukunimi'::varchar as sukunimi,
        data ->> 'hetu'::varchar as hetu,
        data ->> 'kotikunta'::varchar as kotikunta,
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
