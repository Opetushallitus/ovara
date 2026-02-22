#!/bin/bash

set -eo pipefail

echo "Käynnistetään testin DBT Runner"

while [ $# -gt 0 ]; do
  case "$1" in
    --parameters*|-p*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      parameters="${1#*=}"
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done

ecscluster=$(aws ecs list-clusters | jq -r '.clusterArns | .[0]' | cut -d "/" -f2)
taskdefinition=$(aws ecs list-task-definitions --family-prefix testiEcsStacktestidbttaskScheduledTaskDef029C43B9 --sort DESC | jq -r '.taskDefinitionArns | .[0]' | cut -d "/" -f2)
assignpublicip=$(aws events list-targets-by-rule --rule testi-scheduledFargateTaskRule | jq -r '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.AssignPublicIp')
securitygroups=$(aws events list-targets-by-rule --rule testi-scheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.SecurityGroups')
subnets=$(aws events list-targets-by-rule --rule testi-scheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.Subnets')
awsvpcconfiguration=$(jq -c -n --argjson subnets "$subnets" \
                               --argjson securityGroups "$securitygroups" \
                               --arg assignPublicIp "$assignpublicip" \
                               '$ARGS.named')
networkconfiguration=$(jq -c -n --argjson awsvpcConfiguration "$awsvpcconfiguration" '$ARGS.named')

if [[ -z "$parameters" ]]; then
  echo "Starting DBT without any extra paramaters"
  command="aws ecs run-task --cluster $ecscluster --task-definition $taskdefinition --launch-type="FARGATE" --network-configuration '$networkconfiguration'"
  echo "$command"
  eval "$command"
else
  echo "Starting DBT with extra paramaters"
  overrides="{ \"containerOverrides\": [ { \"name\": \"ScheduledContainer\"}, { \"command\": [ \"bash\", \"/root/run.sh\", \"--parameters=\\\"$parameters\\\"\" ] } ] }"
  command="aws ecs run-task --cluster $ecscluster --task-definition $taskdefinition --launch-type='FARGATE' --network-configuration '$networkconfiguration' --overrides='$overrides'"
  echo "$command"
  eval "$command"
fi
