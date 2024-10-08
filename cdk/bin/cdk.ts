#!/usr/bin/env node
import 'source-map-support/register';

import * as cdk from 'aws-cdk-lib';
import * as cdkNag from 'cdk-nag';

import { BastionStack } from '../lib/bastion-stack';
import { CertificateStack } from '../lib/certificate-stack';
import { getGenericStackProps } from '../lib/config';
import { DatabaseStack } from '../lib/database-stack';
import { LambdaStack } from '../lib/lambda-stack';
import { MonitorStack } from '../lib/monitor-stack';
import { NetworkStack } from '../lib/network-stack';
import { Route53Stack } from '../lib/route53-stack';
import { S3Stack } from '../lib/s3-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment') || process.env.ENVIRONMENT;
const props = getGenericStackProps(environmentName);
const config = props.config;

const accountId = process.env.CDK_DEFAULT_ACCOUNT;

const monitorStack = new MonitorStack(app, `${config.environment}-MonitorStack`, {
  ...props,
});

const route53Stack = new Route53Stack(app, `${config.environment}-Route53Stack`, {
  ...props,
});

const certificateStack = new CertificateStack(
  app,
  `${config.environment}-CertificateStack`,
  {
    ...props,
    env: {
      region: 'us-east-1',
      account: accountId,
    },
    crossRegionReferences: true,
  }
);

const networkStack = new NetworkStack(app, `${config.environment}-NetworkStack`, props);

const s3Stack = new S3Stack(app, `${config.environment}-S3Stack`, {
  ovaraWildcardCertificate: certificateStack.ovaraWildcardCertificate,
  ...props,
  crossRegionReferences: true,
  slackAlarmIntegrationSnsTopic: monitorStack.slackAlarmIntegrationSnsTopic,
  zone: route53Stack.publicHostedZone,
});

const databaseStack = new DatabaseStack(app, `${config.environment}-DatabaseStack`, {
  publicHostedZone: route53Stack.publicHostedZone,
  vpc: networkStack.vpc,
  slackAlarmIntegrationSnsTopic: monitorStack.slackAlarmIntegrationSnsTopic,
  ...props,
});

new LambdaStack(app, `${config.environment}-LambdaStack`, {
  vpc: networkStack.vpc,
  siirtotiedostoBucket: s3Stack.siirtotiedostoBucket,
  siirtotiedostotKmsKey: s3Stack.siirtotiedostotKmsKey,
  siirtotiedostoQueue: s3Stack.siirtotiedostoQueue,
  slackAlarmIntegrationSnsTopic: monitorStack.slackAlarmIntegrationSnsTopic,
  ...props,
});

new BastionStack(app, `${config.environment}-BastionStack`, {
  auroraSecurityGroup: databaseStack.auroraSecurityGroup,
  deploymentS3Bucket: s3Stack.deploymentS3Bucket,
  publicHostedZone: route53Stack.publicHostedZone,
  vpc: networkStack.vpc,
  ...props,
});

cdk.Aspects.of(app).add(new cdkNag.AwsSolutionsChecks({ verbose: true }));
