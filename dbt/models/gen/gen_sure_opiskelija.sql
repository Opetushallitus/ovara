{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['henkilo_oid']}
    ],
    post_hook =  "{{ create_pk('resource_id') }}"
    )
}}

with source as (
    select * from {{ ref('int_sure_opiskelija') }}
    where not poistettu
),

final as (
    select
    resourceid as resource_id,
        {{ dbt_utils.star(
            from=ref('int_sure_opiskelija'),
            except=['poistettu', 'source', 'resourceid']
            )
        }},
        source as lahde
    from source
)

select * from final
