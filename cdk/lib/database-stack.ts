import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface DatabaseStackProps extends GenericStackProps {
  publicHostedZone: route53.IHostedZone;
  vpc: ec2.IVpc;
}

export class DatabaseStack extends cdk.Stack {
  public readonly auroraSecurityGroup: ec2.ISecurityGroup;
  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const vpc = props.vpc;
    const publicHostedZone = props.publicHostedZone;

    const kmsKey = new kms.Key(this, 'rds-key', {
      enableKeyRotation: true,
    });
    kmsKey.addAlias(`alias/${config.environment}/rds`);

    this.auroraSecurityGroup = new ec2.SecurityGroup(this, 'PostgresSecurityGroup', {
      securityGroupName: `${config.environment}-opiskelijavalinnanraportointi-aurora`,
      vpc: vpc,
      allowAllOutbound: true,
    });

    new cdk.CfnOutput(this, 'PostgresSecurityGroupId', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-aurora-securitygroupid`,
      description: 'Postgres security group id',
      value: this.auroraSecurityGroup.securityGroupId,
    });

    const parameterGroup = new rds.ParameterGroup(this, 'pg', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_5,
      }),
      parameters: {
        shared_preload_libraries: 'pg_stat_statements,pg_hint_plan,auto_explain,pg_cron',
      },
    });

    const auroraCluster = new rds.DatabaseCluster(
      this,
      `${config.environment}-OpiskelijavalinnanraportointiAuroraCluster`,
      {
        engine: rds.DatabaseClusterEngine.auroraPostgres({
          version: rds.AuroraPostgresEngineVersion.VER_15_5,
        }),
        serverlessV2MinCapacity: 0.5,
        serverlessV2MaxCapacity: 16,
        deletionProtection: false, // TODO: päivitä kun siirrytään tuotantoon
        removalPolicy: cdk.RemovalPolicy.DESTROY, // TODO: päivitä kun siirrytään tuotantoon
        writer: rds.ClusterInstance.serverlessV2('Writer', {
          caCertificate: rds.CaCertificate.RDS_CA_RDS4096_G1,
          enablePerformanceInsights: false,
        }),
        // TODO: lisää readeri tuotantosetuppiin
        vpc,
        vpcSubnets: {
          subnets: vpc.privateSubnets,
        },
        securityGroups: [this.auroraSecurityGroup],
        credentials: rds.Credentials.fromUsername('oph'),
        storageEncrypted: true,
        storageEncryptionKey: kmsKey,
        parameterGroup,
      }
    );

    new route53.CnameRecord(this, `${config.environment}-DbCnameRecord`, {
      recordName: `raportointi.db`,
      zone: publicHostedZone,
      domainName: auroraCluster.clusterEndpoint.hostname,
      ttl: cdk.Duration.seconds(300),
    });

    new cdk.CfnOutput(this, `${config.environment}-PostgresEndpoint`, {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-db-dns`,
      description: 'Aurora endpoint',
      value: `raportointi.db.${config.publicHostedZone}`,
    });
  }
}
