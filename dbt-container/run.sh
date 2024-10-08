#!/bin/bash

set -e

echo "Running Ovara DBT script..."

echo "Listing contents of /root folder"
ls -Al /root

echo "Listing contents of /root/dbt folder"
ls -Al /root/dbt

cd dbt
. venv/bin/activate

dbt build --target=prod "$1"

exit 0
