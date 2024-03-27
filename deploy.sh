#!/usr/bin/env bash

set -eo pipefail

if [ $# == 0  ] || [ $# -gt 3 ]
then
    echo 'please provide 1-3 arguments. Use -h or --help for usage information.'
    exit 0
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -h | --help | help )
    echo '''
Usage: deploy.sh [-h] [-d] deploy/build/delete environment stack

Light weight version of cdk.sh in cloud-base

positional arguments:
  deploy                builds and deploys the stack to target environment, environment must be supplied.
  delete                deletes the stack from target environment, environment must be supplied.
  build                 only builds the Lambda & synthesizes CDK (useful when developing)
  stack                 name of the stack (BastionStack, DatabaseStack, NetworkStack or All)
  environment           Environment name (tuotanto, testi or kehitys)

optional arguments:
  -h, --help            Show this help message and exit
  -d, --dependencies    Clean and install dependencies before deployment (i.e. run npm ci)
  '''
    exit 0
    ;;

    -d | --dependencies)
    dependencies="true"
    shift
    ;;

    build)
    build="true"
    shift
    ;;

    deploy)
    deploy="true"
    shift
    ;;

    delete)
    delete="true"
    shift
    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done

git_root=$(git rev-parse --show-toplevel)
environment=${POSITIONAL[~-1]}
stack_parameter=${POSITIONAL[~-2]}
if [[ "${stack_parameter}" =~ "all" ]]; then
  stack="--all"
else
  stack="$environment-$stack_parameter"
fi

## Profiles are defined in user's .aws/config
if [[ "${environment}" =~ ^(tuotanto)$ ]]; then
    aws_profile="oph-opiskelijavalinnan-raportointi-prod"
elif [[ "${environment}" =~ ^(testi)$ ]]; then
    aws_profile="oph-opiskelijavalinnan-raportointi-qa"
elif [[ "${environment}" =~ ^(kehitys)$ ]]; then
    aws_profile="oph-opiskelijavalinnan-raportointi-qa"
else
    echo "Unknown environment: ${environment}"
    exit 0
fi

if [[ -n "${dependencies}" ]]; then
    echo "Installing CDK dependencies.."
    cd "${git_root}/cdk/" && npm ci
fi

if [[ "${build}" == "true" ]]; then
    echo "Building code and synthesizing CDK template"
    export ENVIRONMENT=$environment
    cd "${git_root}/cdk/"
    npm run build
    npx cdk synth
fi

if [[ "${deploy}" == "true" ]]; then
   echo "Building code, synhesizing CDK code and deploying to environment: $environment"
   cd "${git_root}/cdk/"
   cdk deploy $stack -c "environment=$environment" --profile $aws_profile
fi

if [[ "${delete}" == "true" ]]; then
   echo "Deleting stack from environment: $environment"
   cd "${git_root}/cdk/"
   cdk destroy $stack -c "environment=$environment" --profile $aws_profile
fi
