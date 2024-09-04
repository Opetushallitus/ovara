{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['oid']}
        ]
    )
}}

with raw as (
    select * from {{ ref('dw_organisaatio_ryhma') }}
),

final as (
    select
        oid,
        jsonb_build_object(
            'en', nimi_en,
            'sv', nimi_sv,
            'fi', nimi_fi
        ) as ryhma_nimi
    from raw
)

select * from final
