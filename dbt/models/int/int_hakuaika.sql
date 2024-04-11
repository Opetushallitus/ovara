{{
  config(
    indexes=[{'columns': ['hakuaika_id']}],
    materialized='incremental'
   )
}}

with hakukohde as 
(
    select 
    jsonb_array_elements(hakuajat) hakuaika from {{ref('dw_kouta_hakukohde')}}
),
haku as 
(
    select 
    jsonb_array_elements(hakuajat) hakuaika from {{ref('dw_kouta_haku')}}
),

hakuajat as 
(
    select distinct  
    (hakuaika ->> 'alkaa')::timestamptz as alkaa,
    (hakuaika ->> 'paattyy')::timestamptz as paattyy
    from hakukohde
    union all
    select distinct  
    (hakuaika ->> 'alkaa')::timestamptz as alkaa,
    (hakuaika ->> 'paattyy')::timestamptz as paattyy
    from haku

 ),
 final as 
 (
    select 
    {{ dbt_utils.generate_surrogate_key(
      ['alkaa',
      'paattyy']
  ) }} as hakuaika_id,
    alkaa,
    paattyy,
    current_timestamp::timestamptz as luotu,
    current_timestamp::timestamptz as muokattu
    from hakuajat
 )

select final.* from final
{% if is_incremental() -%}
    right join {{this}} this on final.hakuaika_id=this.hakuaika_id
    where this.alkaa is null
{% endif %}

