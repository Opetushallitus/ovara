#!/bin/bash

set -e

echo "Running Lampi-siirtäjä..."

IS_RUNNING=$(aws dynamodb execute-statement --statement "SELECT onKaynnissa FROM ecsProsessiOnKaynnissa WHERE prosessi='lampi-scheduled-task'" | jq -r ' .Items.[0].onKaynnissa.S ')
echo "Onko edellinen ajo käynnissä: $IS_RUNNING"
if [[ "$IS_RUNNING" = "true" ]]; then
  echo "ERROR: Edellinen ajo on vielä käynnissä."
  exit 1
fi

echo "Merkitään DynamoDB:hen että prosessi on ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='true' WHERE prosessi='lampi-scheduled-task' RETURNING ALL NEW *"

start=$(date +%s)

cd /root
# if-rakenne ohittaa set -e:n, jotta prosessilukko ehditään vapauttaa ennen
# virheeseen poistumista.
if java -jar ovara-lampi-siirtaja.jar; then
  is_error="0"
else
  is_error="1"
fi

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

echo "Merkitään DynamoDB:hen että prosessi ei ole enää ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='false' WHERE prosessi='lampi-scheduled-task' RETURNING ALL NEW *"

if [ $is_error -eq "1" ]; then
  exit 1
fi

exit 0
