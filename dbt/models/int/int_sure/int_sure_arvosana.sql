{{
    config(
        materialized = 'table',
        indexes = [
        ]
    )
}}

with raw as (
    select
        *,
        row_number() over (partition by resourceid order by muokattu desc) as row_nr
    from {{ ref('dw_sure_arvosana') }}
),

int as (
    select * from raw
    where row_nr = 1
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
        case --yo-ravosanojen palauttaminen
            when aine = 'AINEREAALI' then lisatieto
            when aine = 'REAALI' then --vanha reaali
                case
                    when lisatieto = 'ET' then 'RY'
                    when lisatieto = 'UO' then 'RO'
                    when lisatieto = 'UE' then 'RR'
                    else 'REAALI_'||lisatieto
                end
            when aine = 'A' then --pitkät kielet
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
            when aine = 'B' then --keskipitkät kielet
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
            when aine = 'C' then --lyhyet kielet
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
            when aine = 'AI' then --äidinkielet
                case
                    when lisatieto = 'IS' then 'I'
                    when lisatieto = 'RU' then 'O'
                    when lisatieto = 'FI' then 'A'
                    when lisatieto = 'ZA' then 'Z'
                    when lisatieto = 'QS' then 'W'
                    else 'AI_' || lisatieto
                end
            when aine = 'VI2' then --suomi/ruotsi toisena kielenä
                case
                    when lisatieto = 'RU' then 'OS'
                    when lisatieto = 'FI' then 'AS'
                    else 'VI2_' || lisatieto
                end
            when aine = 'PITKA' then --pitkä matematiikka
                case
                    when lisatieto = 'MA' then 'M'
                    else 'PITKA_' || lisatieto
                end
            when aine = 'LYHYT' then --lyhyt matematiikka
                case
                    when lisatieto = 'MA' then 'N'
                    else 'LYHYT_' || lisatieto
                end
            when aine = 'SAKSALKOUL' then -- saksalaisen koulun saksan kielen koe
                case
                    when lisatieto = 'SA' then 'S9'
                    else 'SAKSALKOUL_' || lisatieto
                end
            when aine = 'KYPSYYS' then --Englanninkielinen kypsyyskoe
                case
                    when lisatieto = 'LA' then 'L1'
                    else 'KYPSYYS_' || lisatieto
                end
            when aine = 'D' then --latina
                case
                    when lisatieto = 'LA' then 'L1'
                    else 'D_' || lisatieto
                end
            else 'XXX'
        end as yo_aine
    from int
)

select * from final
