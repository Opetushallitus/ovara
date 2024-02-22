#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

//import { AuroraStack } from '../lib/aurora-stack';
import { BastionStack } from '../lib/bastion-stack';
import { getConfig } from '../lib/config';
import { NetworkStack } from '../lib/network-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment');
const props = getConfig(environmentName);

//new AuroraStack(app, 'AuroraStack', {});
//new BastionStack(app, 'BastionStack', {});
new NetworkStack(app, 'NetworkStack', props);
