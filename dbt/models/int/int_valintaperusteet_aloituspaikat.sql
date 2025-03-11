{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohde_oid']}
    ]
    )
}}

with hakukohde as ( --noqa: PRS
    select * from {{ ref('int_valintaperusteet_hakukohde') }}
),

rows as (
    select
        hakukohde_oid,
        (
            jsonb_array_elements(
                jsonb_array_elements(valinnanvaiheet)->'valintatapajono'
            )->> 'aloituspaikat'
        )::int as aloituspaikat,
        (
            jsonb_array_elements(
                jsonb_array_elements(valinnanvaiheet)->'valintatapajono'
            )->> 'siirretaanSijoitteluun'
        )::boolean as siirretaanSijoitteluun
    from hakukohde
),

final as (
    select
        hakukohde_oid,
        sum (
            case
                when siirretaanSijoitteluun then aloituspaikat
                else 0 end
        ) as aloituspaikat
    from rows
    group by hakukohde_oid
)

select * from final
