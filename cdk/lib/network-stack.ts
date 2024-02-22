import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { Config, OpiskelijavalinnanRaportointiStackProps } from './config';

export class NetworkStack extends cdk.Stack {
  constructor(
    scope: Construct,
    id: string,
    props: OpiskelijavalinnanRaportointiStackProps
  ) {
    super(scope, id, props);

    const config: Config = props.config;

    new route53.HostedZone(this, 'OpiskelijavalinnanRaportointiHostedZone', {
      zoneName: config.publicHostedZone,
    });

    new ec2.Vpc(this, `${config.environment}-private-Vpc`, {
      natGateways: 0,
    });
  }
}
