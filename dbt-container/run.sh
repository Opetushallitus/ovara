#!/bin/bash

set -e

echo "Running Ovara DBT script..."

start=$(date +%s)

cd dbt
. venv/bin/activate

dbt seed -s raw_taulut --target=prod
dbt run-operation create_raw_tables --target=prod

if [[ -z "$1" ]]; then
  echo "Running DBT without any extra paramaters"
  dbt build --target=prod
  echo "Finished running DBT"
else
  echo "Running DBT with extra paramaters: $1"
  dbt build --target=prod "$1"
  echo "Finished running DBT"
fi

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

start=$(date +%s)
dbt run-operation tempdata_cleanup --target=prod
echo "Siivouksen kesto `expr $(date +%s) - ${start}` s"

exit 0
