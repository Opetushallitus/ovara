#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

import { AuroraStack } from '../lib/aurora-stack';
import { BastionStack } from '../lib/bastion-stack';
import { getOpiskelijavalinnanRaportointiStackProps } from '../lib/config';
import { NetworkStack } from '../lib/network-stack';

const app = new cdk.App();
const environmentName = app.node.tryGetContext('environment');
const props = getOpiskelijavalinnanRaportointiStackProps(environmentName);

new AuroraStack(app, 'AuroraStack', props);
new BastionStack(app, 'BastionStack', props);
new NetworkStack(app, 'NetworkStack', props);
