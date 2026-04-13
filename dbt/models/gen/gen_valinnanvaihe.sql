{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with valinnanvaihe as (
    select
        hakukohde_oid,
        valinnanvaiheet
    from {{ ref('int_valintaperusteet_hakukohde') }}
    where jsonb_array_length(valinnanvaiheet) > 0
),

final as (
    select
        "valinnanVaiheOid" as valinnanvaihe_id,
        vape.hakukohde_oid,
        vava.nimi as valinnanvaihe_nimi,
        vava."valinnanVaiheJarjestysluku" as valinnanvaihe_jarjestysluku,
        vava.aktiivinen as valinnanvaihe_aktiivinen,
        vava."valinnanVaiheTyyppi" as valinnanvaihe_tyyppi
    from valinnanvaihe as vape
    cross join lateral jsonb_to_recordset(vape.valinnanvaiheet) as vava (
        "valinnanVaiheOid" text,
        nimi text,
        "valinnanVaiheJarjestysluku" int,
        aktiivinen boolean,
        "valinnanVaiheTyyppi" text
    )
)

select * from final
