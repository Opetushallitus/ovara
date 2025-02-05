#!/bin/bash

set +e

echo "Running Ovara DBT script..."

start=$(date +%s)

cd dbt
. venv/bin/activate

IS_RUNNING=$(aws dynamodb execute-statement --statement "SELECT onKaynnissa FROM ecsProsessiOnKaynnissa WHERE prosessi='dbt-scheduled-task'" | jq -r ' .Items.[0].onKaynnissa.S ')
echo "Onko edellinen ajo käynnissä: $IS_RUNNING"
if [[ "$IS_RUNNING" = "true" ]]; then
  echo "ERROR: Edellinen ajo on vielä käynnissä."
  exit 1
fi

echo "Merkitään DynamoDB:hen että prosessi on ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='true' WHERE prosessi='dbt-scheduled-task' RETURNING ALL NEW *"

dbt seed -s raw_taulut --target=prod
dbt run-operation create_raw_tables --target=prod

is_error="0"

if [[ -z "$1" ]]; then
  echo "Running DBT without any extra paramaters"
  if dbt build --target=prod ; then
  	is_error="0"
  else
    is_error="1"
  fi
  echo "Finished running DBT"
else
  echo "Running DBT with extra paramaters: $1"
  if dbt build --target=prod "$1"; then
  	is_error="0"
  else
    is_error="1"
  fi
  echo "Finished running DBT"
fi

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

start=$(date +%s)
dbt run-operation tempdata_cleanup --target=prod
echo "Siivouksen kesto `expr $(date +%s) - ${start}` s"

echo "Generoidaan dokumentaatio"
dbt docs generate --target=prod

echo "Kopioidaan dokumentaatio S3:een"
aws s3 cp ./target/catalog.json s3://$OVARA_DOC_BUCKET/dbt/catalog.json
aws s3 cp ./target/index.html s3://$OVARA_DOC_BUCKET/dbt/index.html
aws s3 cp ./target/manifest.json s3://$OVARA_DOC_BUCKET/dbt/manifest.json

echo "Kopioidaan lokit S3:een"
CURRENT_TIME="$(TZ=Europe/Helsinki date +%Y-%m-%d_%H:%M:%S%Z)"
echo "$CURRENT_TIME"
aws s3 cp ./logs s3://$DBT_LOGS_BUCKET/$CURRENT_TIME --recursive --include 'logs/dbt.log*' --content-type 'text/plain'

echo "Merkitään DynamoDB:hen että prosessi ei ole enää ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='false' WHERE prosessi='dbt-scheduled-task' RETURNING ALL NEW *"

if [ $is_error -eq "1" ]; then
	echo "Error: Ajossa tapahtui virhe"
	exit 1
fi

exit 0
