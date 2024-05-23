{{
  config(
    materialized = 'table',
    )
}}

with source as (
      select * from {{ source('ovara', 'onr_henkilo') }}
),

final as
(
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'etunimet'::varchar as etunimet,
        data ->> 'sukunimi'::varchar as sukunimi,
        data ->> 'hetu'::varchar as hetu,
        (data ->> 'syntymaaika')::date as syntymaaika,
        (data ->> 'aidinkieli')::int as aidinkieli,
        (data ->> 'kansalaisuus')::varchar as kansalaisuus,
        (data ->> ' sukupuoli')::int as sukupuoli,
        data ->> 'turvakielto'::varchar = 't' as turvakielto,
        data ->> 'yksiloityvtj'::varchar = 't' as yksiloityvtj,
        {{ metadata_columns() }}
    from source
)

select * from final

