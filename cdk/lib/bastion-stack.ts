import * as cdk from 'aws-cdk-lib';
import * as asg from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elb from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import { Protocol } from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface BastionStackProps extends GenericStackProps {
  auroraSecurityGroup: ec2.ISecurityGroup;
  deploymentS3Bucket: s3.IBucket;
  publicHostedZone: route53.IHostedZone;
  vpc: ec2.IVpc;
}

export class BastionStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: BastionStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const vpc = props.vpc;
    const publicHostedZone = props.publicHostedZone;

    new s3deploy.BucketDeployment(this, 'DeployBastionFiles', {
      sources: [s3deploy.Source.asset('./files/bastion')],
      destinationBucket: props.deploymentS3Bucket,
      destinationKeyPrefix: 'bastion',
    });

    const bastionInternalSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-BastionSecurityGroup`,
      {
        vpc: vpc,
        allowAllOutbound: true,
        description: 'Internal security group for bastion host',
        securityGroupName: `${config.environment}-BastionSecurityGroup`,
      }
    );

    props.auroraSecurityGroup.addIngressRule(
      bastionInternalSecurityGroup,
      ec2.Port.tcp(5432),
      'DB sallittu bastionille'
    );

    const bastionExternalSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-BastionExternalSecurityGroup`,
      {
        vpc: vpc,
        allowAllOutbound: true,
        description: 'External security group for bastion host',
        securityGroupName: `${config.environment}-BastionExternalSecurityGroup`,
      }
    );

    const nlbAccessLogsBucketName = `${config.environment}-bastion-nlb-access-logs`;
    const nlbAccessLogsBucket = new s3.Bucket(this, nlbAccessLogsBucketName, {
      bucketName: nlbAccessLogsBucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: new kms.Key(this, `${nlbAccessLogsBucketName}-s3BucketKMSKey`, {
        enableKeyRotation: true,
      }),
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${nlbAccessLogsBucketName}-server-access-logs`
      ),
    });

    const bastionNetworkLoadBalancer = new elb.NetworkLoadBalancer(
      this,
      `${config.environment}-bastion-nlb`,
      {
        loadBalancerName: `${config.environment}-bastion-nlb`,
        vpc: vpc,
        internetFacing: true,
        ipAddressType: elb.IpAddressType.IPV4,
        crossZoneEnabled: true,
        securityGroups: [bastionExternalSecurityGroup],
        vpcSubnets: {
          subnetType: ec2.SubnetType.PUBLIC,
        },
      }
    );

    bastionNetworkLoadBalancer.logAccessLogs(nlbAccessLogsBucket);

    const bastionAutoScalingGroup = new asg.AutoScalingGroup(
      this,
      `${config.environment}-BastionAutoScalingGroup`,
      {
        autoScalingGroupName: `${config.environment}-BastionAutoScalingGroup`,
        vpc: vpc,
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MICRO),
        machineImage: ec2.MachineImage.latestAmazonLinux2023({
          cpuType: ec2.AmazonLinuxCpuType.ARM_64,
        }),
        blockDevices: [
          {
            deviceName: '/dev/xvda',
            volume: asg.BlockDeviceVolume.ebs(20, {
              encrypted: true,
              volumeType: asg.EbsDeviceVolumeType.GP3,
              deleteOnTermination: true,
            }),
          },
        ],
        requireImdsv2: true,
        securityGroup: bastionInternalSecurityGroup,
        vpcSubnets: {
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        maxCapacity: 1,
        minCapacity: 1,
        instanceMonitoring: asg.Monitoring.BASIC,
        ssmSessionPermissions: true,
      }
    );
    bastionAutoScalingGroup.addUserData('sudo dnf -y install postgresql@15');

    const nlbListener = bastionNetworkLoadBalancer.addListener(
      `${config.environment}-bastion-nlb-ssh-listener`,
      {
        port: 22,
      }
    );

    const bastionNetworkTargetGroup = new elb.NetworkTargetGroup(
      this,
      `${config.environment}-bastion-nlb-target-group`,
      {
        targetGroupName: `${config.environment}-bastion-nlb-target-group`,
        port: 22,
        protocol: Protocol.TCP_UDP,
        connectionTermination: true,
        vpc: vpc,
      }
    );

    bastionAutoScalingGroup.attachToNetworkTargetGroup(bastionNetworkTargetGroup);

    nlbListener.addTargetGroups(
      `${config.environment}-bastion-nlb-target-groups`,
      bastionNetworkTargetGroup
    );

    [
      '54.195.163.193/32', // Opintopolku AWS VPN
      '3.251.15.161/32', // Opintopolku AWS VPN
      '54.72.176.32/32', // Opintopolku AWS VPN
    ].forEach((ipAddress) => {
      bastionExternalSecurityGroup.addIngressRule(
        ec2.Peer.ipv4(ipAddress),
        ec2.Port.tcp(22),
        'Allow SSH access from trusted ip addresses'
      );
      bastionInternalSecurityGroup.addIngressRule(
        ec2.Peer.ipv4(ipAddress),
        ec2.Port.tcp(22),
        'Allow SSH access from trusted ip addresses'
      );
    });

    props.deploymentS3Bucket.grantRead(bastionAutoScalingGroup.grantPrincipal);

    new route53.CnameRecord(this, `${config.environment}-BastionCnameRecord`, {
      recordName: `bastion`,
      zone: publicHostedZone,
      domainName: bastionNetworkLoadBalancer.loadBalancerDnsName,
      ttl: cdk.Duration.seconds(300),
    });

    new cdk.CfnOutput(this, `${config.environment}-BastionEndpoint`, {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-bastion-dns`,
      description: 'Bastion endpoint',
      value: `bastion.${config.publicHostedZone}`,
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: 'Wildcard rights are only for internal use.' },
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      { id: 'AwsSolutions-L1', reason: 'TODO: Fix or add proper reason' },
      { id: 'AwsSolutions-AS3', reason: 'TODO: Fix or add proper reason' },
      { id: 'AwsSolutions-IAM4', reason: 'TODO: Fix or add proper reason' },
    ]);
  }
}
