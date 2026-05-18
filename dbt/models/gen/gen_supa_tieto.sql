{{
    config(
    materialized = 'incremental',
    incremental_strategy= 'append',
    unlogged=true,
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']},
        {'columns':['avain']}
    ],
    pre_hook =
    [
        """{% if is_incremental() %}
        delete from {{ this }} as t
        using
        (
            select distinct hakemus_oid
            from {{ ref('int_supa_tieto') }}
            where dw_metadata_dw_stored_at > (select max (dw_metadata_dw_stored_at) from {{ this }})
        )
        as s where t.hakemus_oid=s.hakemus_oid;
        {% endif %}
        """
    ]
    )
}}

with source as not materialized (
    select * from {{ ref('int_supa_tieto') }}
    {% if is_incremental() %}
        where dw_metadata_dw_stored_at >= (
            select
                coalesce(
                    max(dw_metadata_dw_stored_at),
                    '1900-01-01'::timestamptz
                )
            from {{ this }}
        )
    {% endif %}
)

select * from source
