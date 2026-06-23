{% macro remove_old_valintatapajonos() %}

{#
Tätää makroa käytetään siivoamaan testissä vanhoja valintatapajonoja datatuonnin jälkeen.
#}

with valintatapajonos as (
	select
		hakukohde_oid,
		oid as valintatapajono_oid
	from {{ ref('int_valintaperusteet_hakukohde') }}

	cross join lateral jsonb_to_recordset(valinnanvaiheet) valinnanvaihe (
	valintatapajono jsonb
	)

	cross join lateral jsonb_to_recordset(valintatapajono) as v (
	oid text
	)

)

delete from {{ ref('int_valintarekisteri_valinnantulos') }} a
where not exists (
	select 1 from valintatapajonos b where a.hakukohde_oid =b.hakukohde_oid and a.valintatapajono_oid =b.valintatapajono_oid
	)

{% endmacro %}