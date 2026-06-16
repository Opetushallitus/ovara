{{
  config(
    materialized = 'incremental',
    incremental_strategy = 'append',
    pre_hook = [
        """
        {% if is_incremental() %}
        with to_delete as (
        select distinct henkilo_oid from {{ ref('int_supa_opiskeluoikeus') }} a
        where jsonb_array_length(data -> 'kkOpiskeluoikeudet') > 0
        and a.dw_metadata_dw_stored_at >= (select max (dw_metadata_dw_stored_at) from {{ this }})
        )

        delete from {{ this }} a
        using to_delete b
        where a.henkilo_oid=b.henkilo_oid
        {% endif %}
        """
    ],
    indexes = [
        {'columns':['dw_metadata_dw_stored_at']},
        {'columns':['henkilo_oid']}
    ],
    post_hook = [
        "{{ create_pk('tunniste') }}"
    ]
    )
}}

with opiskeluoikeudet as (
	select
		henkilo_oid,
		data,
		dw_metadata_dw_stored_at
	from {{ ref('int_supa_opiskeluoikeus') }}
	where jsonb_array_length(data -> 'kkOpiskeluoikeudet') > 0
    {% if is_incremental() %}
    and dw_metadata_dw_stored_at > (select max (dw_metadata_dw_stored_at) from {{ this }})
    {% endif %}
),

organisaatio as materialized (
    select
		organisaatio_oid,
		oppilaitosnumero
	from {{ ref('int_organisaatio_organisaatio') }}
	where oppilaitosnumero is not null
),

rows as (
	select
	    kkoo."tunniste",
		opoi.henkilo_oid,
	    kkoo."nimi"->>'fi' as nimi_fi,
	    kkoo."nimi"->>'sv' as nimi_sv,
	    kkoo."nimi"->>'en' as nimi_en,
	    kkoo."kieli",
	    kkoo."alkuPvm" as alku_pvm,
	    kkoo."loppuPvm" as loppu_pvm,
	    kkoo."myontaja",
	    kkoo."supaTila" as supa_tila,
	    kkoo."tyyppiKoodi" as tyyppi_koodi,
	    kkoo."koulutusKoodi" as koulutus_koodi,
	    kkoo."rahoitusLahde" as rahoitus_lahde,
	    kkoo."virtaTunniste" as virta_tunniste,
	    kkoo."entiteetinTyyppi" as entiteetin_tyyppi,
	    kkoo."isTutkintoonJohtava" as is_tutkintoon_johtava,
	    kkoo."luokittelu",
	    kkoo."virtaTila"->>'arvo' as virta_tila_arvo,
	    kkoo."virtaTila"->>'koodisto' as virta_tila_koodisto,
	    kkoo."metadata"->>'lahdejarjestelma' as lahdejarjestelma,
	    kkoo."metadata"->>'lahdeTunniste' as lahde_tunniste,
	    kkoo."metadata"->>'parserVersio' as parser_versio,
	    (kkoo."metadata"->>'parserointiHetki')::timestamptz as parserointi_hetki,
	    dw_metadata_dw_stored_at
	from opiskeluoikeudet as opoi

	inner join lateral jsonb_to_recordset(opoi.data-> 'kkOpiskeluoikeudet') as kkoo(
	    "nimi"                  jsonb,
	    "kieli"                 text,
	    "alkuPvm"               date,
	    "loppuPvm"              date,
	    "metadata"              jsonb,
	    "myontaja"              text,
	    "supaTila"              text,
	    "tunniste"              uuid,
	    "virtaTila"             jsonb,
	    "luokittelu"            text,
	    "suoritukset"           jsonb,
	    "tyyppiKoodi"           text,
	    "koulutusKoodi"         text,
	    "rahoitusLahde"         text,
	    "virtaTunniste"         text,
	    "entiteetinTyyppi"      text,
	    "isTutkintoonJohtava"   boolean
	) on true
),

final as (
    select
        rows.*,
        orga.organisaatio_oid
    from rows as rows
    left join organisaatio as orga on rows.myontaja = orga.oppilaitosnumero
)

select * from final
