{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select distinct on (resourceid)
        *
    from {{ ref('dw_sure_arvosana') }}
    order by resourceid, muokattu desc
),

final as (
    select
        resourceid,
        suoritus,
        arvosana,
        asteikko,
        aine,
        lisatieto,
        valinnainen,
        muokattu,
        deleted,
        pisteet,
        myonnetty,
        source,
        jarjestys,
        arvot,
        case --yo-arvosanojen palauttaminen
            when aine = 'AINEREAALI' then lisatieto
            when aine = 'REAALI' --vanha reaali
                then
                    case
                        when lisatieto = 'ET' then 'RY'
                        when lisatieto = 'UO' then 'RO'
                        when lisatieto = 'UE' then 'RR'
                        else 'REAALI_' || lisatieto
                    end
            when aine = 'A' --pitkät kielet
                then
                    case
                        when lisatieto = 'SA' then 'SA'
                        when lisatieto = 'EN' then 'EA'
                        when lisatieto = 'UN' then 'HA'
                        when lisatieto = 'VE' then 'VA'
                        when lisatieto = 'IT' then 'TA'
                        when lisatieto = 'RA' then 'FA'
                        when lisatieto = 'FI' then 'CA'
                        when lisatieto = 'RU' then 'BA'
                        when lisatieto = 'ES' then 'PA'
                        when lisatieto = 'PG' then 'GA'
                        else 'A_' || lisatieto
                    end
            when aine = 'B' --keskipitkät kielet
                then
                    case
                        when lisatieto = 'SA' then 'SB'
                        when lisatieto = 'EN' then 'EB'
                        when lisatieto = 'UN' then 'HB'
                        when lisatieto = 'VE' then 'VB'
                        when lisatieto = 'IT' then 'TB'
                        when lisatieto = 'RA' then 'FB'
                        when lisatieto = 'FI' then 'CB'
                        when lisatieto = 'RU' then 'BB'
                        when lisatieto = 'ES' then 'PB'
                        when lisatieto = 'PG' then 'GB'
                        else 'B_' || lisatieto
                    end
            when aine = 'C' --lyhyet kielet
                then
                    case
                        when lisatieto = 'SA' then 'SC'
                        when lisatieto = 'EN' then 'EC'
                        when lisatieto = 'UN' then 'HC'
                        when lisatieto = 'VE' then 'VC'
                        when lisatieto = 'IT' then 'TC'
                        when lisatieto = 'RA' then 'FC'
                        when lisatieto = 'FI' then 'CC'
                        when lisatieto = 'RU' then 'BC'
                        when lisatieto = 'ES' then 'PC'
                        when lisatieto = 'PG' then 'GC'
                        when lisatieto = 'IS' then 'IC'
                        when lisatieto = 'ZA' then 'DC'
                        when lisatieto = 'KR' then 'KC'
                        when lisatieto = 'QS' then 'QC'
                        when lisatieto = 'LA' then 'L7'
                        else 'C_' || lisatieto
                    end
            when aine = 'AI' --äidinkielet
                then
                    case
                        when lisatieto = 'IS' then 'I'
                        when lisatieto = 'RU' then 'O'
                        when lisatieto = 'FI' then 'A'
                        when lisatieto = 'ZA' then 'Z'
                        when lisatieto = 'QS' then 'W'
                        else 'AI_' || lisatieto
                    end
            when aine = 'VI2' --suomi/ruotsi toisena kielenä
                then
                    case
                        when lisatieto = 'RU' then 'OS'
                        when lisatieto = 'FI' then 'AS'
                        else 'VI2_' || lisatieto
                    end
            when aine = 'PITKA' --pitkä matematiikka
                then
                    case
                        when lisatieto = 'MA' then 'M'
                        else 'PITKA_' || lisatieto
                    end
            when aine = 'LYHYT' --lyhyt matematiikka
                then
                    case
                        when lisatieto = 'MA' then 'N'
                        else 'LYHYT_' || lisatieto
                    end
            when aine = 'SAKSALKOUL' -- saksalaisen koulun saksan kielen koe
                then
                    case
                        when lisatieto = 'SA' then 'S9'
                        else 'SAKSALKOUL_' || lisatieto
                    end
            when aine = 'KYPSYYS' --Englanninkielinen kypsyyskoe
                then
                    case
                        when lisatieto = 'LA' then 'L1'
                        else 'KYPSYYS_' || lisatieto
                    end
            when aine = 'D' --latina
                then
                    case
                        when lisatieto = 'LA' then 'L1'
                        else 'D_' || lisatieto
                    end
            else 'XXX'
        end as yo_aine
    from raw
)

select * from final
