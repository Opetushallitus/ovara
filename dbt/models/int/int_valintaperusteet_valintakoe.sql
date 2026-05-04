{{
  config(
    materialized = 'table',
    indexes = [
        {'columns' : ['valintakoe_id']}
    ]
    )
}}

with valintaperusteet as (
    select
        hakukohde_oid,
        valinnanvaiheet
    from {{ ref('int_valintaperusteet_hakukohde') }}
),

final as (
    select
        vako.oid as valintakoe_id,
        vape.hakukohde_oid,
        vako.nimi as valintakoe_nimi,
        vako.kuvaus as valintakoe_kuvaus,
        vako.peritty as valintakoe_peritty,
        vako.tunniste as valintakoe_tunniste,
        vako.aktiivinen as valintakoe_aktiivinen,
        vako."kutsunKohde" as valintakoe_kutsun_kohde,
        vako."lastModified" as muokattu,
        vako."kutsutaankoKaikki" as valintakoe_kutsutaanko_kaikki,
        vako."lahetetaankoKoekutsut" as valintakoe_lahetetaanko_koekutsut
    from valintaperusteet as vape
    cross join lateral jsonb_array_elements(vape.valinnanvaiheet) as vava
    cross join lateral jsonb_to_recordset(vava -> 'valintakoe') as vako (
                "oid" text,
                "nimi" text,
                "kuvaus" text,
                "peritty" bool,
                "tunniste" text,
                "aktiivinen" bool,
                "kutsunKohde" text,
                "lastModified" timestamptz,
                "kutsutaankoKaikki" bool,
                "lahetetaankoKoekutsut" bool
    )
    where jsonb_array_length(vava -> 'valintakoe') > 0
)

select * from final
