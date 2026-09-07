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
    select * from {{ ref('int_sure_suoritus') }}
    where not poistettu
),

final as (
    select
        resourceid as resource_id,
        komo,
        myontaja,
        tila,
        valmistuminen::date,
        henkilo_oid,
        yksilollistaminen,
        suorituskieli,
        muokattu,
        "source" as lahde,
        vahvistettu,
        arvot::jsonb
from source
)

select * from final
