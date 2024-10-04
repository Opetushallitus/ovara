with source as (
    select * from {{ source('ovara', 'onr_henkilo') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
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
        {{ metadata_columns() }}
    from source
)

select * from final
