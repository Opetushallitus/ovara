#!/usr/bin/env bash

set -eo pipefail

if [ $# -lt 2 ]; then
  echo "Establish ssh connection to a bastion in one of our cloud environments using SSM."
  echo ""
  echo "Missing arguments:"
  echo ""
  echo "  environment          environment name (kehitys, testi or tuotanto)"
  echo "  command              command"
  echo "  tunnel               local_port:romete_host:remote_port (optional)"
  echo ""
  echo "Examples:"
  echo "connect to testi bastion:                       ./ssh.sh testi bash"
  echo "connect to testi bastion with tunnel:           ./ssh.sh testi bash 5432:raportointi.db.opiskelijavalinnan-raportointi.testiopintopolku.fi:5432"
  exit 1
fi

envname=${1}
command=${2}
if [[ ${envname} == "tuotanto" ]]; then
    profile="oph-opiskelijavalinnan-raportointi-prod"
else
    profile="oph-opiskelijavalinnan-raportointi-qa"
fi

instanceId=`aws ec2 describe-instances --profile ${profile} --filters 'Name=tag:Name,Values=testi-BastionStack/testi-BastionAutoScalingGroup' 'Name=instance-state-name,Values=running' --output text --query 'Reservations[*].Instances[*].InstanceId'`

if [ -z "${3}" ]
then
  aws ssm start-session --profile ${profile} --document-name AWS-StartInteractiveCommand --parameters command="${command}" --target ${instanceId}
else
  tunnel=${3}
  IFS=":" read -ra tunnel_array <<< "$tunnel"
  local_port=${tunnel_array[0]}
  remote_host=${tunnel_array[1]}
  remote_port=${tunnel_array[2]}
  aws ssm start-session --profile ${profile} --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters host="$remote_host",portNumber="${remote_port}",localPortNumber="${local_port}" --target ${instanceId}
fi
