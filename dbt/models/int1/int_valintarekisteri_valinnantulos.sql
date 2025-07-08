{{
    config(
        materialized = 'incremental',
        unique_key = ['valinnantulos_id'],
        incremental_strategy = 'merge',
        indexes = [
            {'columns':['valinnantulos_id','valintatiedon_pvm']},
        ]
    )
}}

with tulos as not materialized (
    select *
    from {{ ref('dw_valintarekisteri_valinnantulos') }}
    {% if target.name == 'prod' and is_incremental() %}
    where dw_metadata_dw_stored_at > coalesce (
	    (
    		select  start_time from {{ source('ovara', 'completed_dbt_runs') }}
	      	where raw_table = 'valintarekisteri_valinnantulos'
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
            tls1.valinnantulos_id = tls2.valinnantulos_id
            and tls1.muokattu < tls2.muokattu
    {% if is_incremental() %}
        left join {{ this }} as tls3
            on
                tls1.valinnantulos_id = tls3.valinnantulos_id
    {% endif %}
    where
        tls2.valinnantulos_id is null
        {%- if is_incremental() %}
            and (
                tls1.muokattu > tls3.valintatiedon_pvm
                or tls3.valintatiedon_pvm is null
            )
        {%- endif %}

),

final as (
    select
        valinnantulos_id,
        {{ hakutoive_id() }},
        {{ dbt_utils.generate_surrogate_key(['hakemus_oid','hakukohde_oid','valintatapajono_oid']) }}
        as hakemus_hakukohde_valintatapa_id,
        hakukohde_oid,
        valintatapajono_oid,
        hakemus_oid,
        henkilo_oid,
        valinnantila as valinnan_tila,
        ehdollisestihyvaksyttavissa as ehdollisesti_hyvaksyttavissa,
        jsonb_build_object(
            'en', ehdollisenhyvaksymisenehtoen,
            'sv', ehdollisenhyvaksymisenehtosv,
            'fi', ehdollisenhyvaksymisenehtofi
        ) as ehdollisen_hyvaksymisen_ehto,
        jsonb_build_object(
            'en', valinnantilankuvauksentekstien,
            'sv', valinnantilankuvauksentekstisv,
            'fi', valinnantilankuvauksentekstifi
        ) as valinnantilan_kuvauksen_teksti,
        julkaistavissa,
        hyvaksyperuuntunut,
        muokattu::date as valintatiedon_pvm
    from int
)

select * from final
