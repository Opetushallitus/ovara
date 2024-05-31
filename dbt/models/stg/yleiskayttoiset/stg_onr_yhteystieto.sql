{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['henkilo_oid']}
    ]
    )
}}

with source as (
      select * from {{ source('ovara', 'onr_yhteystieto') }}
),

final as
(
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'yhteystieto_arvo_tyyppi'::varchar as yhteystieto_arvo_tyyppi,
        data ->> 'alkupera'::varchar as alkupera,
        data ->> 'yhteystieto_arvo'::varchar as yhteystieto_arvo,
        data ->> 'yhteystietotyyppi'::varchar as yhteystietotyyppi,
        {{ metadata_columns() }}
    from source
)

select * from final

