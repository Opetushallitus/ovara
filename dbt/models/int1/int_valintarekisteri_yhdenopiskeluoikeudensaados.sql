{{
  config(
    materialized = 'incremental',
    unique_key = 'hakutoive_id',
    incremental_strategy = 'merge',
    indexes = [
        {'columns':['dw_metadata_stg_stored_at']},
        {'columns':['hakutoive_id']},
    ]
    )
}}

with source as (
    select distinct on (hakutoive_id) * from {{ ref('dw_valintarekisteri_yhdenopiskeluoikeudensaados') }}
    {% if is_incremental() %}
      where dw_metadata_stg_stored_at >= coalesce((select max(dw_metadata_stg_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
    order by
        hakutoive_id asc,
        muokattu desc
),

final as (
    select
        hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        data ->> 'henkiloOid' as henkilo_oid,
        (data ->> 'paateltyAloitusPvm')::date as paatelty_aloituspvm,
        (data -> 'paatettavatOikeudet')::jsonb as paatettavat_oikeudet,
        muokattu,
        {{ metadata_columns() }}
    from source
)

select * from final
