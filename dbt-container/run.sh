#!/bin/bash

set -e

echo "Running Ovara DBT script..."

start=$(date +%s)

cd dbt
. venv/bin/activate

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

exit 0
