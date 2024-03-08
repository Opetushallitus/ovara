import * as cdk from 'aws-cdk-lib';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export class Route53Stack extends cdk.Stack {
  public readonly publicHostedZone: route53.HostedZone;

  constructor(scope: Construct, id: string, props: GenericStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    this.publicHostedZone = new route53.HostedZone(
      this,
      `${config.environment}-OpiskelijavalinnanRaportointiHostedZone`,
      {
        zoneName: config.publicHostedZone,
      }
    );
  }
}
