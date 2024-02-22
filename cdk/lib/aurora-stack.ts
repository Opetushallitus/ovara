import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import { Config, OpiskelijavalinnanRaportointiStackProps } from './config';

export class AuroraStack extends cdk.Stack {
  constructor(
    scope: Construct,
    id: string,
    props: OpiskelijavalinnanRaportointiStackProps
  ) {
    super(scope, id, props);

    const config: Config = props.config;
  }
}
