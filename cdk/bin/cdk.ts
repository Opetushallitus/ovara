#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

//import { BastionStack } from '../lib/bastion-stack';
import { getOpiskelijavalinnanRaportointiStackProps } from '../lib/config';
import { DatabaseStack } from '../lib/database-stack';
import { NetworkStack } from '../lib/network-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment') || process.env.ENVIRONMENT;
const props = getOpiskelijavalinnanRaportointiStackProps(environmentName);

new NetworkStack(app, 'NetworkStack', props);
new DatabaseStack(app, 'DatabaseStack', props);
//new BastionStack(app, 'BastionStack', props);
