#!/bin/bash

set -eo pipefail

echo "Käynnistetään testin DBT Runner"

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

runtaskargs=(--cluster "$ecscluster"
             --task-definition "$taskdefinition"
             --launch-type FARGATE
             --network-configuration "$networkconfiguration")

# Skriptille annetut parametrit välitetään kontin komennolle, josta ne päätyvät
# run.sh:n argumenteiksi ja siitä edelleen dbt build -komennolle.
if [[ $# -gt 0 ]]; then
  echo "Lisäparametrit: $*"
  # Parametrit syötetään jq:lle rivi kerrallaan, koska jq tulkitsisi
  # --select-tyyliset argumentit omiksi optioikseen.
  containeroverrides=$(printf '%s\n' "$@" | jq -c -Rs --arg name ScheduledContainer \
    'split("\n")[:-1] | {containerOverrides: [{name: $name, command: .}]}')
  runtaskargs+=(--overrides "$containeroverrides")
fi

echo "aws ecs run-task ${runtaskargs[*]}"

aws ecs run-task "${runtaskargs[@]}"
