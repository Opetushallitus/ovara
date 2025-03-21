{{
  config(
    materialized = 'incremental',
    on_schema_change = 'append_new_columns',
    unique_key = ['hakemus_versio_id','muokattu'],
    incremental_strategy = 'merge',
    indexes = [
          {'columns': ['hakemus_versio_id','muokattu','tila']},
          {'columns': ['dw_metadata_dw_stored_at']},
      ],
    )
}}

with raw as (
    select distinct on (oid, versio_id, muokattu) * from {{ ref('stg_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(t.dw_metadata_dbt_copied_at) from {{ this }} as t)
    {% endif %}
    order by oid asc, versio_id desc, muokattu desc, dw_metadata_dbt_copied_at desc
)

select
    {{ dbt_utils.star(from=ref('stg_ataru_hakemus')) }},
    current_timestamp as dw_metadata_dw_stored_at
from raw
