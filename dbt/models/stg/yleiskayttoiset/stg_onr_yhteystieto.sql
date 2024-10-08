with source as (
    select * from {{ source('ovara', 'onr_yhteystieto') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})

    {% endif %}
),

int as (
    select
        data ->> 'henkilo_oid'::varchar as henkilo_oid,
        data ->> 'yhteystieto_arvo_tyyppi'::varchar as yhteystieto_arvo_tyyppi,
        data ->> 'alkupera'::varchar as alkupera,
        data ->> 'yhteystieto_arvo'::varchar as yhteystieto_arvo,
        data ->> 'yhteystietotyyppi'::varchar as yhteystietotyyppi,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
				'henkilo_oid',
				'yhteystieto_arvo_tyyppi',
                'alkupera',
                'yhteystieto_arvo',
                'yhteystietotyyppi'
			]) }} as yhteystieto_id,
        *
    from int
)

select * from final
