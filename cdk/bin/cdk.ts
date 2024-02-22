#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import {AuroraStack} from "../lib/aurora-stack";
import {BastionStack} from "../lib/bastion-stack";
import {VpcStack} from "../lib/vpc-stack";

const app = new cdk.App();

new AuroraStack(app, 'AuroraStack', {});
new BastionStack(app, 'BastionStack', {});
new VpcStack(app, 'VpcStack', {});
