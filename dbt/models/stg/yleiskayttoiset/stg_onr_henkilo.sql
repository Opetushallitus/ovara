{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_oid']},
        {'columns':['master_oid']}
    ]
    )
}}

with source as (
      select * from {{ source('ovara', 'onr_henkilo') }}
),

final as
(
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'master_oid'::varchar as master_oid,
        data ->> 'etunimet'::varchar as etunimet,
        data ->> 'sukunimi'::varchar as sukunimi,
        data ->> 'hetu'::varchar as hetu,
        (data ->> 'syntymaaika')::date as syntymaaika,
        data ->> 'aidinkieli' as aidinkieli,
        (data ->> 'kansalaisuus')::varchar as kansalaisuus,
        (data ->> 'sukupuoli')::int as sukupuoli,
        (data ->> 'turvakielto')::boolean = 't' as turvakielto,
        (data ->> 'yksiloityvtj')::boolean = 't' as yksiloityvtj,
        {{ metadata_columns() }}
    from source
)

select * from final

