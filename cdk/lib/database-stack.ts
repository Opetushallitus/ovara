import * as cdk from 'aws-cdk-lib';
import { CfnOutput } from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Alias } from 'aws-cdk-lib/aws-kms';
import * as rds from 'aws-cdk-lib/aws-rds';
import { Construct } from 'constructs';

import { Config, OpiskelijavalinnanRaportointiStackProps } from './config';

export class DatabaseStack extends cdk.Stack {
  constructor(
    scope: Construct,
    id: string,
    props: OpiskelijavalinnanRaportointiStackProps
  ) {
    super(scope, id, props);

    const config: Config = props.config;

    const vpc = ec2.Vpc.fromLookup(this, `Vpc`, {
      vpcName: `NetworkStack/${config.environment}-Vpc`,
    });

    const auroraSecurityGroup = new ec2.SecurityGroup(this, 'PostgresSecurityGroup', {
      securityGroupName: `${config.environment}-opiskelijavalinnanraportointi-aurora`,
      vpc: vpc,
      allowAllOutbound: true,
    });

    new CfnOutput(this, 'PostgresSecurityGroupId', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-aurora-securitygroupid`,
      description: 'Postgres security group id',
      value: auroraSecurityGroup.securityGroupId,
    });

    const parameterGroup = new rds.ParameterGroup(this, 'pg', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_5,
      }),
      parameters: {
        shared_preload_libraries: 'pg_stat_statements,pg_hint_plan,auto_explain,pg_cron',
      },
    });

    new rds.DatabaseCluster(this, 'OpiskelijavalinnanraportointiAuroraCluster', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_5,
      }),
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 16,
      deletionProtection: false, // TODO: päivitä kun siirrytään tuotantoon
      removalPolicy: cdk.RemovalPolicy.DESTROY, // TODO: päivitä kun siirrytään tuotantoon
      writer: rds.ClusterInstance.serverlessV2('Writer', {
        caCertificate: rds.CaCertificate.RDS_CA_RDS4096_G1,
        enablePerformanceInsights: true,
      }),
      // TODO: lisää readeri tuotantosetuppiin
      vpc,
      vpcSubnets: {
        subnets: vpc.isolatedSubnets,
      },
      securityGroups: [auroraSecurityGroup],
      credentials: rds.Credentials.fromUsername('oph'),
      storageEncrypted: true,
      storageEncryptionKey: Alias.fromAliasName(
        this,
        'rds-key',
        `alias/${config.environment}/rds`
      ),
      parameterGroup,
    });
  }
}
