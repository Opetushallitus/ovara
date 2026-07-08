{{
  config(
    materialized = 'table',
    post_hook = [
        "{{ create_pk('hakemus_oid') }}"
    ]

    )
}}

with hakemus as (
    select
        hakemus_oid,
        toinen_aste
    from {{ ref('int_ataru_hakemus') }}
    where toinen_aste is not null

),

final as (

    select
        hake.hakemus_oid,
        toas.email,
        toas.kieli,
        toas.asuinmaa,
        toas.huoltajat,
        toas.huoltajat -> 0 ->> 'email' as huoltaja1_email,
        toas.huoltajat -> 0 ->> 'etunimi' as huoltaja1_etunimi,
        toas.huoltajat -> 0 ->> 'sukunimi' as huoltaja1_sukunimi,
        toas.huoltajat -> 0 ->> 'matkapuhelin' as huoltaja1_matkapuhelin,
        toas.huoltajat -> 1 ->> 'email' as huoltaja2_email,
        toas.huoltajat -> 1 ->> 'etunimi' as huoltaja2_etunimi,
        toas.huoltajat -> 1 ->> 'sukunimi' as huoltaja2_sukunimi,
        toas.huoltajat -> 1 ->> 'matkapuhelin' as huoltaja2_matkapuhelin,
        toas.kotikunta,
        toas."personOid" as henkilo_oid,
        toas.lahiosoite,
        toas.hakukohteet,
        toas.postinumero,
        toas.matkapuhelin,
        toas.pohjakoulutus,
        toas."tutkintoKieli" as tutkinto_kieli,
        toas."tutkintoVuosi" as tutkinto_vuosi,
        toas.postitoimipaikka,
        toas."sahkoisenAsioinninLupa" as sahkoisen_asioinnin_lupa,
        toas.koulutusmarkkinointilupa as koulutusmarkkinointi_lupa,
        toas."valintatuloksenJulkaisulupa" as valintatuloksen_julkaisu_lupa,
        toas."kiinnostunutOppisopimusKoulutuksesta" as kiinnostunut_oppisopimuskoulutuksesta,
        toas."kiinnostunutUrheilijanAmmatillisestaKoulutuksesta"
        as kiinnostunut_urheilijan_ammatillisesta_koulutuksesta,

        urli.laji as urh_laji,
        urli.seura as urh_seura,
        urli.liitto as urh_liitto,
        urli.sivulaji as urh_sivulaji,
        urli.keskiarvo as urh_keskiarvo,
        urli.tamakausi as urh_tamakausi,
        urli.peruskoulu as urh_peruskoulu,
        urli.viimekausi as urh_viimekausi,
        urli.toissakausi as urh_toissakausi,
        urli.valmentaja_puh as urh_valmentaja_puh,
        urli.valmentaja_nimi as urh_valmentaja_nimi,
        urli.valmentaja_email as urh_valmentaja_email,
        urli.valmennusryhma_maajoukkue as urh_valmennusryhma_maajoukkue,
        urli.valmennusryhma_piirijoukkue as urh_valmennusryhma_piirijoukkue,
        urli.valmennusryhma_seurajoukkue as urh_valmennusryhma_seurajoukkue,

        uram.laji as urh_amm_laji,
        uram.seura as urh_amm_seura,
        uram.liitto as urh__amm_liitto,
        uram.sivulaji as urh_amm_sivulaji,
        uram.keskiarvo as urh_amm_keskiarvo,
        uram.tamakausi as urh_amm_tamakausi,
        uram.peruskoulu as urh_amm_peruskoulu,
        uram.viimekausi as urh_amm_viimekausi,
        uram.toissakausi as urh_amm_toissakausi,
        uram.valmentaja_puh as urh_amm_valmentaja_puh,
        uram.valmentaja_nimi as urh_amm_valmentaja_nimi,
        uram.valmentaja_email as urh_amm_valmentaja_email,
        uram.valmennusryhma_maajoukkue as urh_amm_valmennusryhma_maajoukkue,
        uram.valmennusryhma_piirijoukkue as urh_amm_valmennusryhma_piirijoukkue,
        uram.valmennusryhma_seurajoukkue as urh_amm_valmennusryhma_seurajoukkue

    from hakemus as hake
    cross join
        lateral jsonb_to_record(hake.toinen_aste) as toas (
            email text,
            kieli text,
            asuinmaa text,
            huoltajat jsonb,
            kotikunta text,
            "personOid" text,
            lahiosoite text,
            hakukohteet jsonb,
            postinumero text,
            matkapuhelin text,
            pohjakoulutus text,
            "tutkintoKieli" text,
            "tutkintoVuosi" text,
            postitoimipaikka text,
            "sahkoisenAsioinninLupa" boolean,
            koulutusmarkkinointilupa boolean,
            "urheilijanLisakysymykset" jsonb,
            "valintatuloksenJulkaisulupa" boolean,
            "kiinnostunutOppisopimusKoulutuksesta" boolean,
            "urheilijanLisakysymyksetAmmatillinen" jsonb,
            "kiinnostunutUrheilijanAmmatillisestaKoulutuksesta" boolean
        )
    left join lateral jsonb_to_record(toas."urheilijanLisakysymykset") as urli (
        laji text,
        seura text,
        liitto text,
        sivulaji text,
        keskiarvo text,
        tamakausi text,
        peruskoulu text,
        viimekausi text,
        toissakausi text,
        valmentaja_puh text,
        valmentaja_nimi text,
        valmentaja_email text,
        valmennusryhma_maajoukkue text,
        valmennusryhma_piirijoukkue text,
        valmennusryhma_seurajoukkue text
    ) on true
    left join lateral jsonb_to_record(toas."urheilijanLisakysymyksetAmmatillinen") as uram (
        laji text,
        seura text,
        liitto text,
        sivulaji text,
        keskiarvo text,
        tamakausi text,
        peruskoulu text,
        viimekausi text,
        toissakausi text,
        valmentaja_puh text,
        valmentaja_nimi text,
        valmentaja_email text,
        valmennusryhma_maajoukkue text,
        valmennusryhma_piirijoukkue text,
        valmennusryhma_seurajoukkue text
    ) on true

)

select * from final
