import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface SqlServerStackProps extends GenericStackProps {
  vpc: ec2.IVpc;
}

export class SqlServerStack extends cdk.Stack {
  public readonly sqlSecurityGroup: ec2.ISecurityGroup;

  constructor(scope: Construct, id: string, props: SqlServerStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    this.sqlSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-SqlServerSecurityGroup`,
      {
        vpc: props.vpc,
        description: 'Security group for SQL Server',
        allowAllOutbound: true,
      }
    );

    const sqlServer = new rds.DatabaseInstance(
      this,
      `${config.environment}-SqlServerInstance`,
      {
        engine: rds.DatabaseInstanceEngine.sqlServerSe({
          version: rds.SqlServerEngineVersion.VER_16,
        }),
        licenseModel: rds.LicenseModel.LICENSE_INCLUDED,
        instanceType: ec2.InstanceType.of(ec2.InstanceClass.M5, ec2.InstanceSize.LARGE),
        vpc: props.vpc,
        credentials: rds.Credentials.fromGeneratedSecret('oph'),
        securityGroups: [this.sqlSecurityGroup],
        multiAz: false,
        allocatedStorage: 20,
        maxAllocatedStorage: 100,
        storageType: rds.StorageType.GP2,
        deletionProtection: false,
        removalPolicy: cdk.RemovalPolicy.DESTROY,
      }
    );

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-RDS2', reason: 'skjfhaskdjhhsajkd' },
      { id: 'AwsSolutions-RDS3', reason: 'skjfhaskdjhhsajkd' },
      { id: 'AwsSolutions-RDS11', reason: 'skjfhaskdjhhsajkd' },
      { id: 'AwsSolutions-RDS6', reason: 'No need IAM Authentication at the moment.' },
      { id: 'AwsSolutions-RDS10', reason: 'Deletion protection will be enabled later.' },
      { id: 'AwsSolutions-SMG4', reason: 'Secret rotation will be added later.' },
      { id: 'AwsSolutions-IAM4', reason: 'Decided to use managed policies for now' },
      { id: 'AwsSolutions-SNS2', reason: 'Not needed with database events' },
      { id: 'AwsSolutions-SNS3', reason: 'Not needed with database events' },
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      { id: 'AwsSolutions-IAM5', reason: 'Wildcard used only for bucket contents' },
      { id: 'AwsSolutions-L1', reason: 'Newest runtime is in use' },
      { id: 'AwsSolutions-ELB2', reason: 'Access logs not needed for TCP/IP traffic' },
    ]);
  }
}
