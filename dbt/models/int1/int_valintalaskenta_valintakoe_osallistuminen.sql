{{
    config(
        materialized = 'incremental',
        unique_key = ['hakemusoid'],
        incremental_strategy = 'merge',
        indexes = [
            {'columns':['hakemusoid','muokattu']},
            {'columns':['dw_metadata_dw_stored_at']}
        ]
    )
}}

with osallistuminen as not materialized (
    select *
    from {{ ref('dw_valintalaskenta_valintakoe_osallistuminen') }}
    {% if target.name == 'prod' and is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce (
	    (
    		select  start_time from {{ source('ovara', 'completed_dbt_runs') }}
	      	where raw_table = 'dw_valintalaskenta_valintakoe_osallistuminen'
	    ),
        '1900-01-01'
    )
    {% endif %}

    {%- if target.name != 'prod' and is_incremental() %}
        where dw_metadata_dw_stored_at > coalesce(
            (
                select max(dw_metadata_dw_stored_at) from {{ this }}
            ),
            '1900-01-01'
        )
    {% endif %}
),

final as (
    select osa1.*
    from osallistuminen as osa1
    left join osallistuminen as osa2
        on
            osa1.hakemusoid = osa2.hakemusoid
            and osa1.muokattu < osa2.muokattu
    {% if is_incremental() %}
        left join {{ this }} as osa3
            on
                osa1.hakemusoid = osa3.hakemusoid
    {% endif %}
    where
        osa2.hakemusoid is null
        {%- if is_incremental() %}
            and (
                osa1.muokattu > osa3.muokattu
                or osa3 is null
            )
        {%- endif %}

)

select * from final
