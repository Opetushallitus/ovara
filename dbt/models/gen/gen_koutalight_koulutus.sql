with koulutus as (
    select * from {{ ref('int_koutalight_koulutus') }}
),

final as (
    select {{
        dbt_utils.star(
            from = ref('int_koutalight_koulutus'),
            except = [
                'dw_metadata_source_timestamp_at',
                'dw_metadata_stg_stored_at',
                'dw_metadata_dbt_copied_at',
                'dw_metadata_filename',
                'dw_metadata_file_row_number',
                'dw_metadata_dw_stored_at'
            ]
        ) }}
    from koulutus
)

select * from final
