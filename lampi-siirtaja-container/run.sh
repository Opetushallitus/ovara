#!/bin/bash

set -e

echo "Running Lampi-siirtäjä..."

start=$(date +%s)

cd /root/lampi-siirtaja
npm start "$POSTGRES_HOST" "$DB_USERNAME" "$DB_PASSWORD" "$LAMPI_S3_BUCKET"

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

exit 0
