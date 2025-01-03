with source as (
    select * from {{ source('ovara', 'valintarekisteri_valinnantulos') }}

    {% if is_incremental() %}

        where dw_metadata_dbt_copied_at > (
            select coalesce(max(dw_metadata_dbt_copied_at), '1899-12-31') from {{ this }}
        )

    {% endif %}
),

raw as (
    select
        data ->> 'hakukohdeOid' as hakukohde_oid,
        data ->> 'valintatapajonoOid' as valintatapajono_oid,
        data ->> 'hakemusOid' as hakemus_oid,
        data ->> 'henkiloOid' as henkilo_oid,
        data ->> 'valinnantila' as valinnantila,
        (data ->> 'ehdollisestiHyvaksyttavissa')::boolean as ehdollisestiHyvaksyttavissa,
        data ->> 'ehdollisenHyvaksymisenEhtoFi' as ehdollisenHyvaksymisenEhtoFi,
        data ->> 'ehdollisenHyvaksymisenEhtoSv' as ehdollisenHyvaksymisenEhtoSv,
        data ->> 'ehdollisenHyvaksymisenEhtoEn' as ehdollisenHyvaksymisenEhtoEn,
        data ->> 'valinnantilanKuvauksenTekstiFI' as valinnantilanKuvauksenTekstiFI,
        data ->> 'valinnantilanKuvauksenTekstiSV' as valinnantilanKuvauksenTekstiSV,
        data ->> 'valinnantilanKuvauksenTekstiEN' as valinnantilanKuvauksenTekstiEN,
        (data ->> 'julkaistavissa')::boolean as julkaistavissa,
        (data ->> 'hyvaksyttyVarasijalta') as hyvaksyttyVarasijalta,
        (data ->> 'hyvaksyPeruuntunut')::boolean as hyvaksyPeruuntunut,
        (data ->> 'valinnantilanViimeisinMuutos')::timestamptz as muokattu,
        {{ metadata_columns() }}
    from source
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key (['hakukohde_oid','valintatapajono_oid','hakemus_oid']) }}
        as valinnantulos_id,
        *
    from raw
)

select * from final
