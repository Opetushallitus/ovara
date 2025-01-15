#!/bin/bash

set -e

echo "Running Lampi-siirtäjä..."

start=$(date +%s)

cd /root
java -jar ovara-lampi-siirtaja.jar

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

exit 0
