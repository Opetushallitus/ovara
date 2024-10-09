#!/bin/bash

set -e

echo "Running Ovara DBT script..."

start=$(date +%s)

echo "Listing contents of /root folder"
ls -Al /root

echo "Listing contents of /root/dbt folder"
ls -Al /root/dbt

cd dbt
. venv/bin/activate
if [[ -z "$1" ]]; then
  echo "Running DBT without any extra paramaters"
  dbt build --target=prod
else
  echo "Running DBT with extra paramaters: $1"
  dbt build --target=prod "$1"
fi

echo Ajon kesto `expr $(date +%s) - ${start}` s

exit 0
