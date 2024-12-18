#!/bin/bash

set -e

echo "Running Lampi-siirtäjä..."

start=$(date +%s)

cd /root/lampi-siirtaja
npm start

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

exit 0
