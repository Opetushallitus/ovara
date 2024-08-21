import * as cdk from 'aws-cdk-lib';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as events from 'aws-cdk-lib/aws-events';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as cdkNag from 'cdk-nag';
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
        serverlessV2MinCapacity: 2,
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
          subnets: vpc.privateSubnets,
        },
        securityGroups: [this.auroraSecurityGroup],
        credentials: {
          username: 'oph',
          password: cdk.SecretValue.ssmSecure(
            `/${config.environment}/aurora/raportointi/master-user-password`
          ),
        },
        storageEncrypted: true,
        storageEncryptionKey: kmsKey,
        parameterGroup,
        iamAuthentication: true,
      }
    );

    new cdk.CfnOutput(this, 'AuroraClusterResourceId', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-aurora-cluster-resourceid`,
      description: 'Aurora cluster resource id',
      value: auroraCluster.clusterResourceIdentifier,
    });

    new cdk.CfnOutput(this, 'DatabaseEndpointName', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-database-endpoint`,
      description: 'Database endpoint name',
      value: auroraCluster.clusterEndpoint.hostname,
    });

    new route53.CnameRecord(this, `${config.environment}-DbCnameRecord`, {
      recordName: `raportointi.db`,
      zone: publicHostedZone,
      domainName: auroraCluster.clusterEndpoint.hostname,
      ttl: cdk.Duration.seconds(300),
    });

    const backupPlan = new backup.BackupPlan(this, 'BackupPlan', {
      backupPlanName: `${config.environment}-ovara-backup-plan`,
      backupVault: new backup.BackupVault(this, `${config.environment}-BackupVault`, {
        backupVaultName: `${config.environment}-ovara-backup-vault`,
      }),
      backupPlanRules: [
        new backup.BackupPlanRule({
          ruleName: `${config.environment}-jatkuva-backup-rule`,
          enableContinuousBackup: true,
          deleteAfter: cdk.Duration.days(35),
          scheduleExpression: events.Schedule.cron({
            hour: '3',
            minute: '0',
          }),
        }),
      ],
    });

    backupPlan.addSelection(`${config.environment}-ovara-aurora-backup-vault-selection`, {
      backupSelectionName: `${config.environment}-ovara-aurora-backup-vault-selection`,
      resources: [backup.BackupResource.fromRdsDatabaseCluster(auroraCluster)],
    });

    new cdk.CfnOutput(this, `${config.environment}-PostgresEndpoint`, {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-db-dns`,
      description: 'Aurora endpoint',
      value: `raportointi.db.${config.publicHostedZone}`,
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-RDS6', reason: 'No need IAM Authentication at the moment.' },
      { id: 'AwsSolutions-RDS10', reason: 'Deletion protection will be enabled later.' },
      { id: 'AwsSolutions-SMG4', reason: 'Secret rotation will be added later.' },
    ]);
  }
}
