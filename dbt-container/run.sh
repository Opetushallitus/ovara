#!/bin/bash

set +e

# Lokitetaan virheet ERROR-alkuisina, jotta CloudWatchin metriikkasuodatin havaitsee ne.
# Huom: nämä eivät aseta is_error-lippua eivätkä muuta skriptin paluuarvoa.
log_error() {
  echo "ERROR: $1"
}

echo "Kontin tiedot:"
cat build.txt
echo ""

echo "Running Ovara DBT script..."

start=$(date +%s)

if ! cd dbt; then
  log_error "Siirtyminen dbt-hakemistoon epäonnistui"
fi
if ! . venv/bin/activate; then
  log_error "Python-virtuaaliympäristön aktivointi epäonnistui"
fi

# asetetaan pipefail, koska muuten putken paluuarvo olisi jq:n eikä aws:n.
if ! IS_RUNNING=$(set -o pipefail; aws dynamodb execute-statement --statement "SELECT onKaynnissa FROM ecsProsessiOnKaynnissa WHERE prosessi='dbt-scheduled-task'" | jq -r ' .Items.[0].onKaynnissa.S '); then
  log_error "Prosessilukon tilan lukeminen DynamoDB:stä epäonnistui"
fi
echo "Onko edellinen ajo käynnissä: $IS_RUNNING"
if [[ "$IS_RUNNING" = "true" ]]; then
  log_error "Edellinen ajo on vielä käynnissä."
  exit 1
fi

echo "Merkitään DynamoDB:hen että prosessi on ajossa"
if ! aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='true' WHERE prosessi='dbt-scheduled-task' RETURNING ALL NEW *" > /dev/null; then
  log_error "Prosessilukon asettaminen DynamoDB:hen epäonnistui"
fi

# Kontille annetut parametrit välitetään dbt build -komennolle sellaisenaan.
# Tyhjät parametrit suodatetaan pois, jotta dbt ei saa tyhjää argumenttia.
extra_parameters=()
for parameter in "$@"; do
  if [[ -n "$parameter" ]]; then
    extra_parameters+=("$parameter")
  fi
done

if [[ ${#extra_parameters[@]} -eq 0 ]]; then
  if ! dbt seed -s tag:seed --target=prod; then
    log_error "dbt seed epäonnistui"
  fi

#  kommentoitu pois koska nämä taulut tarvitaan reilusti aikaisemmin kehitysvaiheessa
#  dbt run-operation create_raw_tables --target=prod
fi

is_error="0"


if [[ ${#extra_parameters[@]} -eq 0 ]]; then
  echo "Running DBT without any extra paramaters"
  if dbt build --target=prod --exclude "resource_type:seed"; then
  	is_error="0"
  else
    is_error="1"
  fi
  echo "Finished running DBT"
else
  echo "Running DBT with extra parameters: ${extra_parameters[*]}"
  if dbt build --target=prod --exclude "resource_type:seed" "${extra_parameters[@]}"; then
  	is_error="0"
  else
    is_error="1"
  fi
  echo "Finished running DBT"
fi

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

if [[ ${#extra_parameters[@]} -eq 0 ]]; then
  if [ $is_error -eq "0" ]; then
    start=$(date +%s)
    if ! dbt run-operation tempdata_cleanup --target=prod; then
      log_error "dbt run-operation tempdata_cleanup epäonnistui"
    fi
    echo "Siivouksen kesto `expr $(date +%s) - ${start}` s"

    echo "Generoidaan dokumentaatio"
    if ! dbt docs generate --target=prod; then
      log_error "Dokumentaation generointi epäonnistui"
    fi

    echo "Kopioidaan dokumentaatio S3:een"
    if ! aws s3 cp ./target/catalog.json s3://$OVARA_DOC_BUCKET/dbt/catalog.json; then
      log_error "Dokumentaation (catalog.json) kopiointi S3:een epäonnistui"
    fi
    if ! aws s3 cp ./target/index.html s3://$OVARA_DOC_BUCKET/dbt/index.html; then
      log_error "Dokumentaation (index.html) kopiointi S3:een epäonnistui"
    fi
    if ! aws s3 cp ./target/manifest.json s3://$OVARA_DOC_BUCKET/dbt/manifest.json; then
      log_error "Dokumentaation (manifest.json) kopiointi S3:een epäonnistui"
    fi
  fi

  echo "Kopioidaan lokit S3:een"
  CURRENT_TIME="$(TZ=Europe/Helsinki date +%Y-%m-%d_%H:%M:%S%Z)"
  echo "$CURRENT_TIME"
  if ! aws s3 cp ./logs s3://$DBT_LOGS_BUCKET/$CURRENT_TIME --recursive --include 'logs/dbt.log*' --content-type 'text/plain'; then
    log_error "Lokien kopiointi S3:een epäonnistui"
  fi
fi

echo "Merkitään DynamoDB:hen että prosessi ei ole enää ajossa"
if ! aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='false' WHERE prosessi='dbt-scheduled-task' RETURNING ALL NEW *" > /dev/null; then
  log_error "Prosessilukon vapauttaminen DynamoDB:stä epäonnistui"
fi

if [ $is_error -eq "1" ]; then
	log_error "Ajossa tapahtui virhe"
	exit 1
fi

exit 0
