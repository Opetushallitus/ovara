{{
  config(
    materialized = 'incremental',
    unique_key = ['lomake_id_versioid_id'],
    incremental_strategy = 'merge',
    indexes = [
          {'columns': ['lomake_id_versioid_id','muokattu']},
          {'columns': ['dw_metadata_stg_stored_at']},
          {'columns': ['kaksois_urheilija_tutkinto']}
      ],
    post_hook = "create index if not exists dw_lomake_id on {{ this }} ((content ->> 'id'))"
    )
}}

with raw as (
    select distinct on (lomake_id_versioid_id, muokattu) * from {{ ref('stg_ataru_lomake') }}
    {% if is_incremental() %}
        where dw_metadata_stg_stored_at > coalesce(
            (select max(t.dw_metadata_stg_stored_at) from {{ this }} as t),
            '1900-01-01'
        )
    {% endif %}
    order by lomake_id_versioid_id desc, muokattu desc, dw_metadata_dbt_copied_at desc
),

final as (
    select
        {{ dbt_utils.star(from=ref('stg_ataru_lomake')) }},
        current_timestamp as dw_metadata_dw_stored_at
    from raw
)

select * from final
