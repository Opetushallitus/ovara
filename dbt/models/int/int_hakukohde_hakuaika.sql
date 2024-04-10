{{
  config(
    indexes=[{'columns': ['hakuaika_id']}]
)
}}
with raw as (
    select
    oid,
    jsonb_array_elements(hakuajat) hakuaika from {{ref('dw_kouta_hakukohde')}}
),
hakuajat as
(	
	select
	oid,
    (hakuaika ->> 'alkaa')::timestamptz as alkaa,
    (hakuaika ->> 'paattyy')::timestamptz as paattyy
    from raw
)
,
final as
(
	select
    md5(cast(coalesce(cast(alkaa as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(paattyy as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as hakuaika_id,
    oid
    from hakuajat
)

select * from final
