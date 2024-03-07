#!/usr/bin/env bash

set -ou pipefail

if [ $# -lt 3 ]; then
  echo "Execute psql command in a specific postgres DB, or in all postgres DBs in the given environment."
  echo "Usage:"
  echo "$0 <environment> <DB name or 'all' to execute in all DBs in environment> <command to execute> <postgres user, default 'oph'>"
  echo ""
  exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

environment=${1}
db=${2}
command=${3}
user=${4:-oph}

if [[ ${environment} == "sade" ]]; then
  aws_profile="oph-prod"
else
  aws_profile="oph-dev"
fi

ssh_config="${HOME}/.opintopolku/${environment}.ssh.config"

domain=$(jq -cr ".aws.public_hosted_zone" "${script_dir}/../../aws/environments/${environment}/environment.json")

if [[ ${db} == "all" ]]; then
  dbs_in_env=$(jq -cr ".postgres | to_entries[] | .key" "${script_dir}/../../aws/environments/${environment}/environment.json")

  for db in ${dbs_in_env}; do
    if [[ ${user} == "app" ]]; then
      password=$(aws ssm get-parameter --name "/${environment}/postgresqls/${db}/app-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
    else
      password=$(aws ssm get-parameter --name "/${environment}/postgresqls/${db}/master-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
    fi
    echo "${db}"
    remote_cmd="PGPASSWORD=${password} psql -h ${db}.db.${domain} -U ${user} --dbname ${db} --command \"${command}\""
    ssh -t -F "${ssh_config}" "bastion.${domain}" "${remote_cmd}"
  done
else
  if [[ ${user} == "app" ]]; then
    password=$(aws ssm get-parameter --name "/${environment}/postgresqls/${db}/app-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
  else
    password=$(aws ssm get-parameter --name "/${environment}/postgresqls/${db}/master-user-password" --with-decryption --region eu-west-1 --profile "${aws_profile}" | jq -cr ".Parameter.Value")
  fi
  echo "${db}"
  remote_cmd="PGPASSWORD=${password} psql -h ${db}.db.${domain} -U ${user} --dbname ${db} --command \"${command}\""
  ssh -t -F "${ssh_config}" "bastion.${domain}" "${remote_cmd}"
fi
