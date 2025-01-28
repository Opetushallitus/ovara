{{
  config(
    materialized = 'view',
    )
}}

with haku as (
    select * from {{ ref('int_kouta_haku') }}
),

parameter as (
    select * from {{ ref('int_ohjausparametrit_parameter') }}
),

final as (
    select
        haku.haku_oid,
        haku.haku_nimi,
        haku.externalid as external_id,
        haku.tila,
        haku.organisaatiooid as organisaatio_oid,
        haku.hakutapakoodiuri,
        haku.hakukohteenliittamisentakaraja,
        haku.hakukohteenmuokkaamisentakaraja,
        haku.hakukohteenliittajaorganisaatiot,
        haku.kohdejoukkokoodiuri,
        haku.kohdejoukontarkennekoodiuri,
        haku.koulutuksenalkamiskausi,
        haku.hakuajat,
        para.vastaanotto_paattyy,
        para.hakijakohtainen_paikan_vastaanottoaika
    from haku
    left join parameter as para on haku.haku_oid = para.haku_oid
)

select * from final
