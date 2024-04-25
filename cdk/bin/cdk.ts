#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AwsSolutionsChecks } from 'cdk-nag';

import { BastionStack } from '../lib/bastion-stack';
import { CertificateStack } from '../lib/certificate-stack';
import { getGenericStackProps } from '../lib/config';
import { DatabaseStack } from '../lib/database-stack';
import { LambdaStack } from '../lib/lambda-stack';
import { NetworkStack } from '../lib/network-stack';
import { Route53Stack } from '../lib/route53-stack';
import { S3Stack } from '../lib/s3-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment') || process.env.ENVIRONMENT;
const props = getGenericStackProps(environmentName);
const config = props.config;

const route53Stack = new Route53Stack(app, `${config.environment}-Route53Stack`, props);

const certificateStack = new CertificateStack(
  app,
  `${config.environment}-CertificateStack`,
  {
    env: {
      region: 'us-east-1',
    },
    crossRegionReferences: true,
    publicHostedZone: route53Stack.publicHostedZone,
    ...props,
  }
);

const networkStack = new NetworkStack(app, `${config.environment}-NetworkStack`, props);

const lamdaStack = new LambdaStack(app, `${config.environment}-LambdaStack`, {
  vpc: networkStack.vpc,
  ...props,
});

const s3Stack = new S3Stack(app, `${config.environment}-S3Stack`, {
  crossRegionReferences: true,
  siirtotiedostoLambda: lamdaStack.siirtotiedostoLambda,
  ovaraWildcardCertificate: certificateStack.ovaraWildcardCertificate,
  ...props,
});

const databaseStack = new DatabaseStack(app, `${config.environment}-DatabaseStack`, {
  publicHostedZone: route53Stack.publicHostedZone,
  vpc: networkStack.vpc,
  siirtotiedostoLambda: lamdaStack.siirtotiedostoLambda,
  ...props,
});

const bastionStack = new BastionStack(app, `${config.environment}-BastionStack`, {
  auroraSecurityGroup: databaseStack.auroraSecurityGroup,
  deploymentS3Bucket: s3Stack.deploymentS3Bucket,
  publicHostedZone: route53Stack.publicHostedZone,
  vpc: networkStack.vpc,
  ...props,
});

cdk.Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
