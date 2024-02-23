import * as cdk from 'aws-cdk-lib';
import { CfnOutput } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { ISecurityGroup } from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface BastionStackProps extends GenericStackProps {
  publicHostedZone: route53.IHostedZone;
  vpc: ec2.IVpc;
}

export class BastionStack extends cdk.Stack {
  public readonly bastionSecurityGroup: ISecurityGroup;
  constructor(scope: Construct, id: string, props: BastionStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const vpc = props.vpc;
    const publicHostedZone = props.publicHostedZone;

    this.bastionSecurityGroup = new ec2.SecurityGroup(this, 'BastionSecurityGroup', {
      vpc: vpc,
      allowAllOutbound: true,
      description: 'Security group for bastion host',
      securityGroupName: 'BastionSecurityGroup',
    });
    this.bastionSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(22),
      'SSH access'
    );

    const bastionHostLinux = new ec2.BastionHostLinux(this, 'BastionHostLinux', {
      vpc: vpc,
      securityGroup: this.bastionSecurityGroup,
      subnetSelection: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    new route53.CnameRecord(this, 'BastionCnameRecord', {
      recordName: `bastion`,
      zone: publicHostedZone,
      domainName: bastionHostLinux.instancePublicDnsName,
    });

    new CfnOutput(this, 'BastionEndpoint', {
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
