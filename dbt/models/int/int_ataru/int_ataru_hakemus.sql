{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'hakemus_oid',
    indexes = [
        {'columns' :['tiedot'], 'type': 'gin'}
    ]
    )
}}

with raw as not materialized (
    select
        *,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as row_nr
    from {{ ref('dw_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(t.dw_metadata_dw_stored_at) from {{ this }} as t)
    {% endif %}

),

final as (
    select
        oid as hakemus_oid,
        {{ dbt_utils.star(from=ref('dw_ataru_hakemus'),except = ['oid']) }},
        case
            when tila = 'inactivated'
                then cast(true as boolean)
            else cast(false as boolean)
        end as poistettu,
      (tiedot ->> '1dc3311d-2235-40d6-88d2-de2bd63e087b')::boolean as urheilijatutkinto_kiinnostaa

    from raw
    where
        row_nr = 1
        and henkilo_oid is not null
)

select * from final
