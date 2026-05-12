{{
  config(
    indexes = [
        {'columns': ['muokattu']},
        {'columns': ['poistettu']},
    ],
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'hakutoive_id',
    pre_hook =
                """
                {% if is_incremental() %}
                update {{this}}
                set poistettu=true::boolean
                where hakemus_oid in (
                    select distinct hakemus_oid from {{ ref('int_ataru_hakemus') }}
                    where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
                )
                {%- endif -%}
                """
    )
}}

with raw as (
    select
        hakemus_oid,
        henkilo_oid,
        hakukohde,
        muokattu,
        tila,
        hakukelpoisuus_asetettu_automaattisesti,
        dw_metadata_dbt_copied_at
    from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > coalesce(
            (select max(dw_metadata_dbt_copied_at) from {{ this }}),
            '1900-01-01'
        )
    {% endif %}
),

hakutoive_raw as (
    select
        hakemus_oid,
        henkilo_oid,
        muokattu,
        tila,
        hakukelpoisuus_asetettu_automaattisesti,
        dw_metadata_dbt_copied_at,
        value as hakukohde_oid,
        ordinality as hakutoivenumero
    from raw
    cross join jsonb_array_elements_text(hakukohde) with ordinality
),

hakutoivenro as (
    select
        {{ hakutoive_id() }},
        *
    from hakutoive_raw
),

final as (
    select
        hakutoive_id,
        {{ dbt_utils.generate_surrogate_key(
            ['hakukohde_oid',
            'henkilo_oid']
            ) }} as hakukohde_henkilo_id,
        hakemus_oid,
        henkilo_oid,
        hakukohde_oid,
        hakutoivenumero,
        hakukelpoisuus_asetettu_automaattisesti ? hakukohde_oid as hakukelpoisuus_asetettu_automaattisesti,
        case
            when tila = 'inactivated'
                then cast(true as boolean)
            else cast(false as boolean)
        end as poistettu,
        muokattu,
        dw_metadata_dbt_copied_at
    from hakutoivenro
)

select * from final
