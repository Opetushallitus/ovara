{{
  config(
    materialized = 'table',
    indexes = [
      {'columns': ['valintaperuste_id']}
    ]
    )
}}

with valintaperuste as ( --noqa: PRS
    select distinct on (id) * from {{ ref('dw_kouta_valintaperuste') }}
    order by id asc, muokattu desc
),

final as (
    select
        *,
        jsonb_build_object(
            'fi', coalesce(nimi_fi, nimi_sv, nimi_en),
            'sv', coalesce(nimi_sv, nimi_fi, nimi_en),
            'en', coalesce(nimi_en, nimi_fi, nimi_sv)
        ) as valintaperuste_nimi
    from valintaperuste
)

select
    id as valintaperuste_id,
    valintaperuste_nimi,
    {{ dbt_utils.star(
          from=ref('dw_kouta_valintaperuste'),
          except=[
              'id',
              'nimi_fi',
              'nimi_sv',
              'nimi_en']) }}
from final
