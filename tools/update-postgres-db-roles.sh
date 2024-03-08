#!/usr/bin/env bash

set -eou pipefail

if [ $# -ne 2 ]; then
  echo "Ensure the given DB or all postgres DBs in the given environment have the 'app' role up-to-date."
  echo "Usage:"
  echo "$0 <environment> <database>"
  echo ""
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment=${1}
db=${2}

if [[ ${environment} == "tuotanto" ]]; then
  aws_profile="oph-opiskelijavalinnan-raportointi-prod"
else
  aws_profile="oph-opiskelijavalinnan-raportointi-qa"
fi

domain=$(jq -cr ".publicHostedZone" "${script_dir}/../cdk/config/${environment}.json")
host="raportointi.db.${domain}"

master_password=$(aws secretsmanager get-secret-value --secret-id "testiOpiskelijavalinnanrapo-UKMEpyFWIyNW" --profile "${aws_profile}" --region eu-west-1 | jq -cr '.SecretString' | jq -cr '.password')
app_password=$(aws ssm get-parameter --name "/${environment}/aurora/raportointi/app-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
readonly_password=$(aws ssm get-parameter --name "/${environment}/aurora/raportointi/readonly-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")

remote_cmd="/home/ec2-user/bastion/ensure-psql-roles-up-to-date.sh ${host} ${db} ${master_password} ${app_password} ${readonly_password} | tee /home/ec2-user/ensure-psql-roles-up-to-date.log"

ssh ec2-user@bastion.opiskelijavalinnan-raportointi.testiopintopolku.fi "${remote_cmd}"
