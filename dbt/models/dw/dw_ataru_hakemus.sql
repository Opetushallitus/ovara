{{
  config(
    materialized = 'incremental',
    unique_key = ['oid','versio_id','muokattu'],
    incremental_strategy = 'merge',
    indexes = [
          {'columns': ['oid','versio_id','muokattu']},
          {'columns': ['dw_metadata_dw_stored_at']}
      ],
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by oid, versio_id, muokattu order by dw_metadata_dbt_copied_at desc) as _row_nr
    from {{ ref('stg_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
)

select
    {{ dbt_utils.star(from=ref('stg_ataru_hakemus')) }},
    current_timestamp as dw_metadata_dw_stored_at
from raw
where _row_nr = 1
