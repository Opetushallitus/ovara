with raw as (
    select
        hakemus_oid,
        kasittelymerkinnat
    from {{ ref('int_ataru_hakemus') }}
),

maksuvelvollisuus as (
    select
        raw.hakemus_oid,
        km ->> 'hakukohde' as hakukohde_oid,                        --noqa: RF02
        km ->> 'state' as tila                                      --noqa: RF02
    from raw, jsonb_array_elements(raw.kasittelymerkinnat) as km    --noqa: AL05
    where
        km ->> 'requirement' = 'payment-obligation'                 --noqa: RF02
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'hakukohde_oid']
            ) }} as hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        case
            when lower(tila) = 'obligated' then 'Velvollinen'
            when lower(tila) = 'not-obligated' then 'Ei velvollinen'
            when lower(tila) = 'unreviewed' then 'Tarkastamatta'
        end
        as tila
    from maksuvelvollisuus
)

select * from final
