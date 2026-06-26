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

virtaluokittelu as (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_virtaopiskeluoikeudenluokittelu') }}
    where viimeisin_versio
),

virtatila as (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_virtaopiskeluoikeudentila') }}
    where viimeisin_versio
),

virtatyyppi as (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_virtaopiskeluoikeudentyyppi') }}
    where viimeisin_versio
),

virtarahoitus as (
    select
        koodiarvo,
        nimi_fi,
        nimi_sv,
        nimi_en
    from {{ ref('int_koodisto_virtarahoituslahde') }}
    where viimeisin_versio
),

koulutuskoodit as (
    select distinct on (split_part(versioitu_koodiuri, '#', 1))
    	koodiarvo,
    	kansallinenkoulutusluokitus2016koulutusastetaso2 as koulutusaste
    from {{ ref('int_koodisto_koulutus_alat_ja_asteet') }}
    order by
        split_part(versioitu_koodiuri, '#', 1),
        split_part(versioitu_koodiuri, '#', 2)::int desc
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
	    kkoo."koulutusKoodi" as koulutus_koodi,
	    kkoo."rahoitusLahde" as virta_rahoituslahde,
	    kkoo."virtaTunniste" as virta_tunniste,
	    kkoo."entiteetinTyyppi" as entiteetin_tyyppi,
	    kkoo."isTutkintoonJohtava" as is_tutkintoon_johtava,
	    kkoo."luokittelu" as virta_opiskeluoikeuden_luokittelu,
        kkoo."virtaTila" ->> 'arvo' as virta_opiskeluoikeuden_tila,
	    kkoo."tyyppiKoodi" as virta_opiskeluoikeuden_tyyppi,
	    kkoo."liittyvaOpiskeluoikeusAvain" as liittyva_opiskeluoikeus_avain,
	    kkoo."metadata" ->> 'lahdejarjestelma' as lahdejarjestelma,
	    kkoo."metadata" ->> 'lahdeTunniste' as lahde_tunniste,
	    kkoo."metadata" ->> 'parserVersio' as parser_versio,
	    (kkoo."metadata" ->> 'parserointiHetki')::timestamptz as parserointi_hetki,
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
	    "isTutkintoonJohtava"   boolean,
        "liittyvaOpiskeluoikeusAvain" text
	) on true
),

final as (
    select
        rows.*,
        orga.organisaatio_oid,
        luok.nimi_fi as virta_luokittelu_nimi_fi,
        luok.nimi_sv as virta_luokittelu_nimi_sv,
        luok.nimi_en as virta_luokittelu_nimi_en,
        tila.nimi_fi as virta_tila_nimi_fi,
        tila.nimi_sv as virta_tila_nimi_sv,
        tila.nimi_en as virta_tila_nimi_en,
        tyyp.nimi_fi as virta_tyyppi_nimi_fi,
        tyyp.nimi_sv as virta_tyyppi_nimi_sv,
        tyyp.nimi_en as virta_tyyppi_nimi_en,
        vira.nimi_fi as virta_rahoituslahde_nimi_fi,
        vira.nimi_sv as virta_rahoituslahde_nimi_sv,
        vira.nimi_en as virta_rahoituslahde_nimi_en,
        koko.koulutusaste,
        virta_opiskeluoikeuden_tila in ('1','2','4') and
	        virta_rahoituslahde not in ('4') and
	        virta_opiskeluoikeuden_tyyppi in ('1','2','3','4') and
	        coalesce(virta_opiskeluoikeuden_luokittelu,'0') not in ('6','7')
        as yos
    from rows as rows
    left join organisaatio as orga on rows.myontaja = orga.oppilaitosnumero
    left join virtaluokittelu as luok on rows.virta_opiskeluoikeuden_luokittelu= luok.koodiarvo
    left join virtatila as tila on rows.virta_opiskeluoikeuden_tila = tila.koodiarvo
    left join virtatyyppi as tyyp on rows.virta_opiskeluoikeuden_tyyppi = tyyp.koodiarvo
    left join koulutuskoodit as koko on rows.koulutus_koodi = koko.koodiarvo
    left join virtarahoitus as vira on rows.virta_rahoituslahde = vira.koodiarvo
)

select * from final
