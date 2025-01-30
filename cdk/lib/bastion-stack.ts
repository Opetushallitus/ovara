import * as cdk from 'aws-cdk-lib';
import * as asg from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elb from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
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

    // const nlbAccessLogsBucketName = `${config.environment}-bastion-nlb-access-logs`;
    // const nlbAccessLogsBucket = new s3.Bucket(this, nlbAccessLogsBucketName, {
    //   objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
    //   blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
    //   encryptionKey: new kms.Key(this, `${nlbAccessLogsBucketName}-s3BucketKMSKey`, {
    //     enableKeyRotation: true,
    //   }),
    //   serverAccessLogsBucket: new s3.Bucket(
    //     this,
    //     `${nlbAccessLogsBucketName}-server-access-logs`
    //   ),
    // });

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

    //bastionNetworkLoadBalancer.logAccessLogs(nlbAccessLogsBucket);

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

    bastionAutoScalingGroup.userData.addCommands(
      'sudo echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config && sudo echo "ClientAliveCountMax 5" >> /etc/ssh/sshd_config && sudo systemctl restart sshd'
    );
    bastionAutoScalingGroup.userData.addCommands(
      'sudo dnf -y install postgresql15 cronie'
    );
    bastionAutoScalingGroup.userData.addCommands(
      `sudo -u ec2-user aws s3 sync s3://${config.environment}-deployment/bastion /home/ec2-user/bastion`
    );
    bastionAutoScalingGroup.userData.addCommands('chmod u+x /home/ec2-user/bastion/*.sh');
    bastionAutoScalingGroup.userData.addCommands(
      "aws secretsmanager get-secret-value --secret-id bastion/public_keys | jq -cr '.SecretString' | sudo -u ec2-user tee /home/ec2-user/.ssh/authorized_keys > /dev/null"
    );
    bastionAutoScalingGroup.userData.addCommands('sudo systemctl enable crond.service');
    bastionAutoScalingGroup.userData.addCommands('sudo systemctl start crond.service');
    bastionAutoScalingGroup.userData.addCommands(
      'sudo mkdir -p /etc/cron.d && echo "*/15 * * * * root aws secretsmanager get-secret-value --secret-id bastion/public_keys | jq -cr \'.SecretString\' | sudo -u ec2-user tee /home/ec2-user/.ssh/authorized_keys > /dev/null" | sudo tee /etc/cron.d/update-ec2-user-ssh-public-keys > /dev/null'
    );

    const nlbListener = bastionNetworkLoadBalancer.addListener(
      `${config.environment}-bastion-nlb-ssh-listener`,
      {
        port: 22,
      }
    );

    const bastionNetworkTargetGroup = new elb.NetworkTargetGroup(
      this,
      `${config.environment}-bastion-nlb-tg`,
      {
        targetGroupName: `${config.environment}-bastion-nlb-tg`,
        port: 22,
        protocol: elb.Protocol.TCP_UDP,
        connectionTermination: true,
        vpc: vpc,
      }
    );

    bastionAutoScalingGroup.attachToNetworkTargetGroup(bastionNetworkTargetGroup);

    nlbListener.addTargetGroups(
      `${config.environment}-bastion-nlb-tgs`,
      bastionNetworkTargetGroup
    );

    [
      '54.195.163.193/32', // Opintopolku AWS VPN
      '3.251.15.161/32', // Opintopolku AWS VPN
      '54.72.176.32/32', // Opintopolku AWS VPN
      '194.136.110.100/32', // Knowit (Helsinki)
      '185.93.49.68/32', // Knowit (Tampere + VPN)
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

    const publicKeySecret = secretsmanager.Secret.fromSecretNameV2(
      this,
      `${config.environment}-bastion-public-keys`,
      'bastion/public_keys'
    );

    publicKeySecret.grantRead(bastionAutoScalingGroup.role);

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: 'Wildcard rights are only for internal use.' },
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      { id: 'AwsSolutions-L1', reason: 'TODO: Fix or add proper reason' },
      { id: 'AwsSolutions-AS3', reason: 'TODO: Fix or add proper reason' },
      { id: 'AwsSolutions-IAM4', reason: 'TODO: Fix or add proper reason' },
      {
        id: 'AwsSolutions-ELB2',
        reason: 'TODO: Add access logs / are they even needed?',
      },
    ]);
  }
}
