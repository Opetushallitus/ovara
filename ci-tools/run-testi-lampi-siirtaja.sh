#!/bin/bash

set -eo pipefail

echo "Käynnistetään testin Lampi-siirtäjä"

ecscluster=$(aws ecs list-clusters | jq -r '.clusterArns | .[0]' | cut -d "/" -f2)
taskdefinition=$(aws ecs list-task-definitions --family-prefix testiEcsStacktestiovaralampisiirtajaScheduledTaskDef9D6D6A5C --sort DESC | jq -r '.taskDefinitionArns | .[0]' | cut -d "/" -f2)
assignpublicip=$(aws events list-targets-by-rule --rule testi-lampiSiirtajaScheduledFargateTaskRule | jq -r '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.AssignPublicIp')
securitygroups=$(aws events list-targets-by-rule --rule testi-lampiSiirtajaScheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.SecurityGroups')
subnets=$(aws events list-targets-by-rule --rule testi-lampiSiirtajaScheduledFargateTaskRule | jq -c '.Targets | map(select(.Id == "Target0")) | .[0] | .EcsParameters.NetworkConfiguration.awsvpcConfiguration.Subnets')
awsvpcconfiguration=$(jq -c -n --argjson subnets "$subnets" \
                               --argjson securityGroups "$securitygroups" \
                               --arg assignPublicIp "$assignpublicip" \
                               '$ARGS.named')
networkconfiguration=$(jq -c -n --argjson awsvpcConfiguration "$awsvpcconfiguration" '$ARGS.named')
command="aws ecs run-task --cluster $ecscluster --task-definition $taskdefinition --launch-type="FARGATE" --network-configuration '$networkconfiguration'"
echo "$command"

eval "$command"
