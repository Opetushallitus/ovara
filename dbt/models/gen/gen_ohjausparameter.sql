{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['haku_oid']}
    ]
    )
}}

with parametrit as (
    select * from {{ ref('int_ohjausparametrit_parameter') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['haku_oid', 'key']) }} as hakuoid_avain_id,
        haku_oid,
        key as avain,
        value as alkuperainen_arvo,
        value ->> 'value' as arvo,
        to_timestamp((value ->> 'date')::bigint / 1000) as aikaleima,
        to_timestamp((value ->> 'dateStart')::bigint / 1000) as aikaleima_alkaa,
        to_timestamp((value ->> 'dateEnd')::bigint / 1000) as aikaleima_paattyy
    from parametrit,
        lateral jsonb_each(arvot)
)

select * from final
