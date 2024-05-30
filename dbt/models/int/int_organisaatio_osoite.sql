{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['organisaatio_oid','organisaatio_oid']}
    ]
    )
}}
with osoite as (
    select * from {{ ref('dw_organisaatio_osoite') }}
),

posti as (
    select * from {{ ref('int_koodisto_posti') }}
),

kieli as (
    select * from {{ ref('int_koodisto_kieli') }}
),

final as (
    select
        osoi.organisaatio_oid,
        osoi.osoitetyyppi,
        osoi.osoite,
        post.koodiarvo as postinumero,
        case when kiel.koodiarvo = 'SV' then post.nimi_sv else post.nimi_fi end as postitoimipaikka,
        osoi.dw_metadata_dbt_copied_at as ladattu
    from osoite as osoi
    inner join posti as post on osoi.postinumero = post.koodiuri and post.viimeisin_versio
    inner join kieli as kiel on osoi.kieli = kiel.versioitu_koodiuri and kiel.viimeisin_versio
)

select * from final
