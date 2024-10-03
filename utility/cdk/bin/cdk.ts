#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as cdkNag from 'cdk-nag';
import { EcrStack } from '../lib/ecr-stack';

const app = new cdk.App();
new EcrStack(app, 'CdkStack', {});

cdk.Aspects.of(app).add(new cdkNag.AwsSolutionsChecks({ verbose: true }));
