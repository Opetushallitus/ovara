#!/usr/bin/env bash

set -eou pipefail

if [ $# -ne 1 ]; then
  echo "Ensure the given DB or all postgres DBs in the given environment have the 'app' role up-to-date."
  echo "Usage:"
  echo "$0 <environment>"
  echo ""
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment=${1}
db="raportointi"

if [[ ${environment} == "tuotanto" ]]; then
  aws_profile="oph-opiskelijavalinnan-raportointi-prod"
else
  aws_profile="oph-opiskelijavalinnan-raportointi-qa"
fi

domain=$(jq -cr ".public_hosted_zone" "${script_dir}/../cdk/config/${environment}.json")
echo "DOMAIN: ${domain}"

master_password=$(aws ssm get-parameter --name "/${environment}/aurora/${db}/master-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
app_password=$(aws ssm get-parameter --name "/${environment}/aurora/${db}/app-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
readonly_password=$(aws ssm get-parameter --name "/${environment}/aurora/${db}/readonly-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")

echo "master_password: ${master_password}"
echo "app_password: ${app_password}"
echo "readonly_password: ${readonly_password}"

remote_cmd="ensure-psql-roles-up-to-date.sh ${db} ${master_password} ${app_password} ${readonly_password}"

ssh -t -F "${ssh_config}" "bastion.${domain}" "${remote_cmd}"
