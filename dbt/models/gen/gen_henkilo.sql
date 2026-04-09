with onr as (
    select * from {{ ref('int_onr_henkilo') }}
),

kansalaisuus as (
    select * from {{ ref('int_onr_kansalaisuus') }}
    where priorisoitu_kansalaisuus
),

final as (
    select
        henk.henkilo_oid,
        henk.master_oid as oppijanumero,
        henk.master as on_master,
        henk.etunimet,
        henk.sukunimi,
        henk.hetu,
        henk.kotikunta,
        henk.syntymaaika,
        henk.aidinkieli,
        henk.kansalaisuus as kaikki_kansalaisuudet,
        kans.kansalaisuus,
        henk.sukupuoli,
        henk.turvakielto,
        henk.yksiloityvtj
    from onr as henk
    left join kansalaisuus as kans on henk.henkilo_oid = kans.henkilo_oid
)

select * from final
