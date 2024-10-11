#!/usr/bin/env bash

set -eo pipefail

if [ $# == 0  ] || [ $# -lt 2 ]
then
    echo 'Please provide at least 1 argument . Use -h or --help for usage information.'
    exit 0
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -h | --help | help )
    echo '''
Usage: deploy.sh [-h] [-d] [-v VERSION] deploy/build/delete environment stack

Light weight version of cdk.sh in cloud-base

positional arguments:
  deploy                builds and deploys the stack to target environment, environment must be supplied.
  delete                deletes the stack from target environment, environment must be supplied.
  build                 only builds the Lambda & synthesizes CDK (useful when developing)
  diff                  show difference between running environment and the template generated from code
  stack                 name of the stack (BastionStack, DatabaseStack, NetworkStack or All)
  environment           Environment name (tuotanto, testi or kehitys)

optional arguments:
  -h, --help            Show this help message and exit
  -d, --dependencies    Clean and install dependencies before deployment (i.e. run npm ci)
  -v VERSION, --version VERSION
                          Frontend version to deploy (e.g. -v ci-256)
  '''
    exit 0
    ;;

    -d | --dependencies)
    dependencies="true"
    shift
    ;;

    -v | --version)
    image="$2"
    shift # past argument
    shift # past value
    ;;

    build)
    build="true"
    shift
    ;;

    deploy)
    deploy="true"
    shift
    ;;

    diff)
    diff="true"
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

#if [[ -n "${image}" ]] && [[ "${stack}" != "${environment}-EcsStack" ]] && [[ "${stack}" != "--all" ]]; then
#  echo "The --version parameter is only supported for the EcsStack stack or all stacks!"
#  exit 1
#fi

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
    cd "${git_root}/cdk/" && npm i -g aws-cdk && npm ci
fi

if [[ "${build}" == "true" ]]; then
    echo "Building code and synthesizing CDK template"
    export ENVIRONMENT=$environment
    cd "${git_root}/cdk/"
    npm run build
    cdk synth --region eu-west-1 --profile $aws_profile
fi

if [[ "${diff}" == "true" ]]; then
    echo "Comparing current template to the running environment"
    export ENVIRONMENT=$environment
    cd "${git_root}/cdk/"
    npm run build
    cdk diff $stack -c "environment=$environment" -c "ecsImageTag=${image}" --region eu-west-1 --profile $aws_profile
fi

if [[ "${deploy}" == "true" ]]; then
   echo "Building code, synhesizing CDK code and deploying to environment: $environment"
   export ENVIRONMENT=$environment
   cd "${git_root}/cdk/"
   cdk deploy $stack -c "environment=$environment" -c "ecsImageTag=${image}" --profile $aws_profile
fi

if [[ "${delete}" == "true" ]]; then
   echo "Deleting stack from environment: $environment"
   export ENVIRONMENT=$environment
   cd "${git_root}/cdk/"
   cdk destroy $stack -c "environment=$environment" --profile $aws_profile
fi
