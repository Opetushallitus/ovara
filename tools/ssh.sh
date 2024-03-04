#!/usr/bin/env bash

set -eou pipefail

if [ $# -lt 1 ]; then
  echo "Establish ssh connection to a bastion in one of our cloud environments using SSM."
  echo ""
  echo "Missing arguments:"
  echo ""
  echo "  environment          environment name (testi or tuotanto)"
  echo ""
  echo "Examples:"
  echo "connect to testi bastion:                       ssh.sh testi"
  exit 1
fi

envname=${1}
if [[ ${envname} == "tuotanto" ]]; then
    profile="oph-opiskelijavalinnan-raportointi-prod"
else
    profile="oph-opiskelijavalinnan-raportointi-qa"
fi

echo "Profile: ${profile}"

instanceId=`aws ec2 describe-instances --profile ${profile} --filters 'Name=tag:Name,Values=Bastion' --output text --query 'Reservations[*].Instances[*].InstanceId'`

aws ssm start-session --profile ${profile} --document-name AWS-StartInteractiveCommand --parameters command="bash -l" --target ${instanceId}
