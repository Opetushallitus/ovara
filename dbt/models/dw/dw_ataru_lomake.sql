{{
  config(
    materialized = 'incremental',
    unique_key = ['id','versio_id','muokattu'],
    incremental_strategy = 'merge',
    indexes = [
          {'columns': ['id','versio_id','muokattu']},
          {'columns': ['dw_metadata_dw_stored_at']}
      ],
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by id, versio_id, muokattu order by dw_metadata_dbt_copied_at desc) as _row_nr
    from {{ ref('stg_ataru_lomake') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(t.dw_metadata_dw_stored_at) from {{ this }} as t)
    {% endif %}
),

final as (
    select
        {{ dbt_utils.star(from=ref('stg_ataru_lomake')) }},
        current_timestamp as dw_metadata_dw_stored_at
    from raw
    where _row_nr = 1
)

select * from final
