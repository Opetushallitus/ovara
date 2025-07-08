{{
    config(
        materialized = 'incremental',
        unique_key = ['valintakoe_hakemus_id'],
        incremental_strategy = 'merge',
        indexes = [
            {'columns':['valintakoe_hakemus_id','muokattu']},
            {'columns':['dw_metadata_dw_stored_at']}
        ]
    )
}}


with pistetieto as not materialized (
    select * from {{ ref('dw_valintapiste_service_pistetieto') }}
    {% if target.name == 'prod' and is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce (
	    (
    		select  start_time from {{ source('ovara', 'completed_dbt_runs') }}
	      	where raw_table = 'valintapiste_service_pistetieto'
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
    select pte1.* from pistetieto as pte1
    left join pistetieto as pte2
        on
            pte1.valintakoe_hakemus_id = pte2.valintakoe_hakemus_id
            and pte1.muokattu < pte2.muokattu
    {% if is_incremental() %}
        left join {{ this }} as pte3
            on
                pte1.valintakoe_hakemus_id = pte3.valintakoe_hakemus_id
    {% endif %}
    where
        pte2.valintakoe_hakemus_id is null
        {%- if is_incremental() %}
            and (
                pte1.muokattu > pte3.muokattu
                or pte3 is null
            )
        {%- endif %}
)


select * from final
