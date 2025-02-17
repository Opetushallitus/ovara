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
        dw_metadata_dbt_copied_at
    from {{ ref('int_ataru_hakemus') }}
    {% if is_incremental() %}
        where dw_metadata_dbt_copied_at > (select max(dw_metadata_dbt_copied_at) from {{ this }})
    {% endif %}
),

latest_hakemus as (
    select
        hakemus_oid,
        henkilo_oid,
        hakukohde,
        muokattu,
        tila,
        dw_metadata_dbt_copied_at
    from raw
),

hakutoive_raw as (
    select
        hakemus_oid,
        henkilo_oid,
        muokattu,
        tila,
        dw_metadata_dbt_copied_at,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid
    from latest_hakemus
),

hakutoivenro as (
    select
        {{ hakutoive_id() }},
        hakemus_oid,
        henkilo_oid,
        hakukohde_oid,
        muokattu,
        tila,
        dw_metadata_dbt_copied_at,
        row_number() over (partition by hakemus_oid) as hakutoivenumero
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
