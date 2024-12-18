with source as (
    select * from {{ source('ovara', 'organisaatio_osoite') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }})

    {% endif %}
),

raw as (
    select
        data ->> 'organisaatio_oid' as organisaatio_oid,
        data ->> 'kieli' as kieli,
        data ->> 'osoitetyyppi' as osoitetyyppi,
        data ->> 'osoite' as osoite,
        data ->> 'postinumero' as postinumero,
        data ->> 'postitoimipaikka' as postitoimipaikka,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key([
				'organisaatio_oid',
				'kieli',
                'osoitetyyppi'
			]) }} as organisaatioosoite_id,
        *
    from raw
)

select * from final
