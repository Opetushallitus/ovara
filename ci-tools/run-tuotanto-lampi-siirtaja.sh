#!/bin/bash

set -eo pipefail

echo "Käynnistetään tuotannon Lampi-siirtäjä"

ecscluster=$(aws ecs list-clusters | jq -r '.clusterArns | .[0]' | cut -d "/" -f2)
taskdefinition=$(aws ecs list-task-definitions --family-prefix tuotantoEcsStacktuotantoovaralampisiirtajaScheduledTaskDef44BFAB1B --sort DESC | jq -r '.taskDefinitionArns | .[0]' | cut -d "/" -f2)
assignpublicip=$(aws events list-targets-by-rule --rule tuotanto-lampiSiirtajaScheduledFargateTaskRule | jq -r '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.AssignPublicIp')
securitygroups=$(aws events list-targets-by-rule --rule tuotanto-lampiSiirtajaScheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.SecurityGroups')
subnets=$(aws events list-targets-by-rule --rule tuotanto-lampiSiirtajaScheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.Subnets')
awsvpcconfiguration=$(jq -c -n --argjson subnets "$subnets" \
                               --argjson securityGroups "$securitygroups" \
                               --arg assignPublicIp "$assignpublicip" \
                               '$ARGS.named')
networkconfiguration=$(jq -c -n --argjson awsvpcConfiguration "$awsvpcconfiguration" '$ARGS.named')
if [[ -z "$1" ]]; then
  echo "Starting DBT without any extra paramaters"
  command="aws ecs run-task --cluster $ecscluster --task-definition $taskdefinition --launch-type="FARGATE" --network-configuration '$networkconfiguration'"
  echo "$command"
  eval "$command"
else
  echo "Starting DBT with extra paramaters"
  overrides="{ \"containerOverrides\": [ { \"command\": [ \"bash\", \"/root/run.sh\", \"'$1'\" ] } ] }"
  command="aws ecs run-task --cluster $ecscluster --task-definition $taskdefinition --launch-type='FARGATE' --network-configuration '$networkconfiguration' --overrides='$overrides'"
  echo "$command"
  echo "Not running command"
fi
