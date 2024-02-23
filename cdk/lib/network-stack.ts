import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { SubnetType } from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export class NetworkStack extends cdk.Stack {
  public readonly publicHostedZone: route53.HostedZone;
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: GenericStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    this.publicHostedZone = new route53.HostedZone(
      this,
      'OpiskelijavalinnanRaportointiHostedZone',
      {
        zoneName: config.publicHostedZone,
      }
    );

    this.vpc = new ec2.Vpc(this, `${config.environment}-Vpc`, {
      natGateways: 0,
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      maxAzs: 3,
      subnetConfiguration: [
        {
          subnetType: SubnetType.PRIVATE_WITH_EGRESS,
          name: `${config.environment}-Vpc-Subnet1`,
          cidrMask: 24,
        },
        {
          subnetType: SubnetType.PRIVATE_WITH_EGRESS,
          name: `${config.environment}-Vpc-Subnet2`,
          cidrMask: 24,
        },
        {
          subnetType: SubnetType.PRIVATE_WITH_EGRESS,
          name: `${config.environment}-Vpc-Subnet3`,
          cidrMask: 24,
        },
      ],
    });
  }
}
