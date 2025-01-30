#!/bin/bash

set -e

echo "Running Lampi-siirtäjä..."

IS_RUNNING=$(aws dynamodb execute-statement --statement "SELECT onKaynnissa FROM ecsProsessiOnKaynnissa WHERE prosessi='lampi-scheduled-task'" | jq ' .Items.[0].onKaynnissa.S ')
if [ $IS_RUNNING == "true" ] ; then
  echo "ERROR: Edellinen ajo on vielä käynnissä."
  exit 1
fi

echo "Merkitetään DynamoDB:hen että prosessi on ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='true' WHERE prosessi='lampi-scheduled-task' RETURNING ALL NEW *"

start=$(date +%s)

cd /root
java -jar ovara-lampi-siirtaja.jar

echo "Ajon kesto `expr $(date +%s) - ${start}` s"

echo "Merkitetään DynamoDB:hen että prosessi ei ole enää ajossa"
aws dynamodb execute-statement --statement "UPDATE ecsProsessiOnKaynnissa SET onKaynnissa='false' WHERE prosessi='lampi-scheduled-task' RETURNING ALL NEW *"

exit 0
