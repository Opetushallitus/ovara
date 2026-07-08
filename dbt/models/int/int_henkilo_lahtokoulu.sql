{{
  config(
    materialized = 'incremental',
    unique_key = 'henkilo_oid',
    incremental_strategy = 'delete+insert',
    indexes = [
        {'columns':['henkilo_oid']},
        {'columns':['dw_metadata_dw_stored_at']},
    ]
    )
}}

with opiskeluoikeus as
(
    select
        henkilo_oid,
        data,
        dw_metadata_dw_stored_at
    from {{ ref('int_supa_opiskeluoikeus') }}
    {% if is_incremental() %}
      where dw_metadata_dw_stored_at > coalesce((select max(dw_metadata_dw_stored_at) from {{ this }}), '1900-01-01')
    {% endif %}
),

final as (
    select
        opoi.henkilo_oid,
        lako.tila,
        lako.luokka,
        lako."oppilaitosOid" as oppilaitos_oid,
        lako."suoritusTyyppi" as suoritus_tyyppi,
        lako."arvosanaPuuttuu" as arvosana_puuttuu,
        lako."suorituksenAlku" as suorituksen_alku,
        lako."suorituksenLoppu" as suorituksen_loppu,
        lako."valmistumisvuosi" as valmistumisvuosi,
        opoi.dw_metadata_dw_stored_at
    from opiskeluoikeus as opoi
    cross join lateral jsonb_to_recordset(data->'lahtokoulut') as lako(
        tila text,
        luokka text,
        "oppilaitosOid" text,
        "suoritusTyyppi" text,
        "arvosanaPuuttuu" boolean,
        "suorituksenAlku" date,
        "suorituksenLoppu" date,
        "valmistumisvuosi" int

        )
)

select * from final