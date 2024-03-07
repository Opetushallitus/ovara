#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

import { BastionStack } from '../lib/bastion-stack';
import { getGenericStackProps } from '../lib/config';
import { DatabaseStack } from '../lib/database-stack';
import { NetworkStack } from '../lib/network-stack';
import { S3Stack } from '../lib/s3-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment') || process.env.ENVIRONMENT;
const props = getGenericStackProps(environmentName);
const config = props.config;

const networkStack = new NetworkStack(app, `${config.environment}-NetworkStack`, props);
const s3Stack = new S3Stack(app, `${config.environment}-S3Stack`, { ...props });
const databaseStack = new DatabaseStack(app, `${config.environment}-DatabaseStack`, {
  publicHostedZone: networkStack.publicHostedZone,
  vpc: networkStack.vpc,
  ...props,
});
const bastionStack = new BastionStack(app, `${config.environment}-BastionStack`, {
  auroraSecurityGroup: databaseStack.auroraSecurityGroup,
  deploymentS3Bucket: s3Stack.deploymentS3Bucket,
  publicHostedZone: networkStack.publicHostedZone,
  vpc: networkStack.vpc,
  ...props,
});
