import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as logs from 'aws-cdk-lib/aws-logs';
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
      `${config.environment}-OpiskelijavalinnanRaportointiHostedZone`,
      {
        zoneName: config.publicHostedZone,
      }
    );

    const vpcCwLogs = new logs.LogGroup(this, 'Log', {
      logGroupName: `/aws/vpc/${config.environment}-Vpc/flowlogs`,
    });

    this.vpc = new ec2.Vpc(this, `${config.environment}-Vpc`, {
      natGateways: config.vpc.netGateways,
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),
      maxAzs: config.vpc.maxAzs,
      subnetConfiguration: [
        {
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          name: `${config.environment}-Vpc-Subnet-Private1`,
          cidrMask: 24,
        },
        {
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          name: `${config.environment}-Vpc-Subnet-Private2`,
          cidrMask: 24,
        },
        {
          subnetType: ec2.SubnetType.PUBLIC,
          name: `${config.environment}-Vpc-Subnet-Public`,
          cidrMask: 24,
        },
      ],
      flowLogs: {
        s3: {
          destination: ec2.FlowLogDestination.toCloudWatchLogs(vpcCwLogs),
          trafficType: ec2.FlowLogTrafficType.ALL,
        },
      },
    });
  }
}
