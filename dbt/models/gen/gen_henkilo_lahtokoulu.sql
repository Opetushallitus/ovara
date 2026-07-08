with source as (
    select * from {{ ref('int_henkilo_lahtokoulu') }}
),

final as (
    select {{ dbt_utils.star(
        from=ref('int_henkilo_lahtokoulu'),
        except=['dw_metadata_dw_stored_at']
    ) }}
    from source
)

select * from final