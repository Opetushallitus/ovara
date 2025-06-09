{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'valinnanvaihe_id',
        indexes = [
            {'columns': ['valinnanvaihe_id']}
            ]
)
}}

with tulos as not materialized (
    select *
    from {{ ref('stg_valintalaskenta_valintalaskennan_tulos') }}
    {% if target.name == 'prod' and is_incremental() %}
    where dw_metadata_stg_stored_at > coalesce (
	    (
    		select  start_time from {{ source('ovara', 'completed_dbt_runs') }}
	      	where raw_table = 'valintalaskenta_valintalaskennan_tulos'
	    ),
        '1900-01-01'
    )
    {% endif %}

),

int as (
    select tls1.*
    from tulos as tls1
    left join tulos as tls2
        on
            tls1.valinnanvaihe_id = tls2.valinnanvaihe_id
            and tls1.muokattu < tls2.muokattu
    {% if is_incremental() %}
        left join {{ this }} as tls3
            on
                tls1.valinnanvaihe_id = tls3.valinnanvaihe_id
    {% endif %}
    where
        tls2.valinnanvaihe_id is null
    {%- if is_incremental() %}
            and (
                tls1.muokattu > tls3.muokattu
                or tls3.muokattu is null
            )
        {%- endif %}

),

final as (
    select distinct on (valinnanvaihe_id)
        *,
        current_timestamp as dw_metadata_dw_stored_at
    from int
    order by valinnanvaihe_id asc, muokattu desc
)

select * from final
