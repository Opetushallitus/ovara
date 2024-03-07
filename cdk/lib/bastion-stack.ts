import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
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

    const bastionSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-BastionSecurityGroup`,
      {
        vpc: vpc,
        allowAllOutbound: true,
        description: 'Security group for bastion host',
        securityGroupName: `${config.environment}-BastionSecurityGroup`,
      }
    );

    props.auroraSecurityGroup.addIngressRule(
      bastionSecurityGroup,
      ec2.Port.tcp(5432),
      'DB sallittu bastionille'
    );

    const bastionHostLinux = new ec2.BastionHostLinux(
      this,
      `${config.environment}-BastionHostLinux`,
      {
        vpc: vpc,
        instanceName: `${config.environment}-Bastion`,
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MICRO),
        machineImage: ec2.MachineImage.latestAmazonLinux2023({
          cpuType: ec2.AmazonLinuxCpuType.ARM_64,
        }),
        blockDevices: [
          {
            deviceName: '/dev/xvda',
            volume: ec2.BlockDeviceVolume.ebs(20, {
              encrypted: true,
              volumeType: ec2.EbsDeviceVolumeType.GP3,
              deleteOnTermination: true,
            }),
          },
        ],
        requireImdsv2: true,
        securityGroup: bastionSecurityGroup,
        subnetSelection: {
          subnetType: ec2.SubnetType.PUBLIC,
        },
      }
    );
    /*
    bastionHostLinux.instance.userData.addCommands(`
      echo "Installing psql" && \
      sudo dnf install -y postgresql15 && \
      echo "Downloading files from S3" && \
      aws s3 sync s3://testi-deployment/bastion /home/ssm-user/bastion
    `);
    */
    /*
    bastionHostLinux.instance.userData.addS3DownloadCommand({
      bucket: props.deploymentS3Bucket,
      bucketKey: '/bastion/update-postgres-db-roles.sh',
      localFile: '/home/ssm-user/update-postgres-db-roles.sh',
      region: config.region,
    });
     */

    props.deploymentS3Bucket.grantRead(bastionHostLinux.grantPrincipal);

    new route53.CnameRecord(this, `${config.environment}-BastionCnameRecord`, {
      recordName: `${config.environment}-bastion`,
      zone: publicHostedZone,
      domainName: bastionHostLinux.instancePublicIp,
      ttl: cdk.Duration.seconds(300),
    });

    new cdk.CfnOutput(this, `${config.environment}-BastionEndpoint`, {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-bastion-dns`,
      description: 'Bastion endpoint',
      value: `bastion.${config.publicHostedZone}`,
    });

    const createSshKeyCommand = 'ssh-keygen -t rsa -f my_rsa_key';
    const pushSshKeyCommand = `aws ec2-instance-connect send-ssh-public-key --region ${cdk.Aws.REGION} --instance-id ${bastionHostLinux.instanceId} --availability-zone ${bastionHostLinux.instanceAvailabilityZone} --instance-os-user ec2-user --ssh-public-key file://my_rsa_key.pub ${config.profile ? `--profile ${config.profile}` : ''}`;
    const sshCommand = `ssh -o "IdentitiesOnly=yes" -i my_rsa_key ec2-user@${bastionHostLinux.instancePublicDnsName}`;

    new cdk.CfnOutput(this, 'CreateSshKeyCommand', { value: createSshKeyCommand });
    new cdk.CfnOutput(this, 'PushSshKeyCommand', { value: pushSshKeyCommand });
    new cdk.CfnOutput(this, 'SshCommand', { value: sshCommand });
  }
}
