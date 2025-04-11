import * as path from 'path';

import * as cdk from 'aws-cdk-lib';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as snsSubscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface DatabaseStackProps extends GenericStackProps {
  publicHostedZone: route53.IHostedZone;
  slackAlarmIntegrationSnsTopic: sns.ITopic;
  vpc: ec2.IVpc;
}

export class DatabaseStack extends cdk.Stack {
  public readonly auroraSecurityGroup: ec2.ISecurityGroup;
  public readonly lampiTiedostoKasiteltyTable: dynamodb.ITableV2;
  public readonly auroraCluster: rds.IDatabaseCluster;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const addActionsToAlarm = (alarm: cloudwatch.Alarm) => {
      alarm.addAlarmAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
      alarm.addOkAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
      alarm.addInsufficientDataAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
    };

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

    const postgresVersion = rds.AuroraPostgresEngineVersion.of(
      config.aurora.version.full,
      config.aurora.version.major
    );

    const parameterGroup = new rds.ParameterGroup(this, 'pg', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: postgresVersion,
      }),
      parameters: {
        shared_preload_libraries: 'pg_stat_statements,pg_hint_plan,auto_explain,pg_cron',
        work_mem: '524288',
        max_parallel_workers_per_gather: '4',
        random_page_cost: '2',
      },
    });

    const auroraCluster = new rds.DatabaseCluster(
      this,
      `${config.environment}-OpiskelijavalinnanraportointiAuroraCluster`,
      {
        engine: rds.DatabaseClusterEngine.auroraPostgres({
          version: postgresVersion,
        }),
        serverlessV2MinCapacity: config.aurora.minCapacity,
        serverlessV2MaxCapacity: config.aurora.maxCapacity,
        deletionProtection: config.aurora.deletionProtection,
        removalPolicy: cdk.RemovalPolicy.RETAIN,
        writer: rds.ClusterInstance.provisioned('Writer', {
          caCertificate: rds.CaCertificate.RDS_CA_RSA4096_G1,
          enablePerformanceInsights: config.aurora.enablePerformanceInsights,
          instanceType: new ec2.InstanceType(config.aurora.writerInstanceType),
        }),
        readers: config.aurora.serverlessReader
          ? [
              rds.ClusterInstance.serverlessV2('Reader', {
                caCertificate: rds.CaCertificate.RDS_CA_RSA4096_G1,
                enablePerformanceInsights: config.aurora.enablePerformanceInsights,
                scaleWithWriter: config.aurora.scaleReaderWithWriter,
              }),
            ]
          : [
              rds.ClusterInstance.provisioned('Reader', {
                caCertificate: rds.CaCertificate.RDS_CA_RSA4096_G1,
                enablePerformanceInsights: config.aurora.enablePerformanceInsights,
                instanceType: new ec2.InstanceType(config.aurora.readerInstanceType),
              }),
            ],
        vpc: vpc,
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
        parameterGroup: parameterGroup,
        iamAuthentication: true,
        backup: {
          retention: cdk.Duration.days(config.aurora.backup.deleteAfterDays),
        },
        enableDataApi: true,
        storageType: config.aurora.iopsStorage
          ? rds.DBClusterStorageType.AURORA_IOPT1
          : rds.DBClusterStorageType.AURORA,
      }
    );
    this.auroraCluster = auroraCluster;

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

    // PrivateLink

    const privateLinkNlbSecurityGroup = new ec2.SecurityGroup(
      this,
      'PrivateLinkNlbsSecurityGroup',
      {
        securityGroupName: `${config.environment}-opiskelijavalinnanraportointi-privatelink-nlb`,
        vpc: vpc,
        allowAllOutbound: true,
      }
    );

    this.auroraSecurityGroup.addIngressRule(
      privateLinkNlbSecurityGroup,
      ec2.Port.tcp(5432),
      'DB sallittu PrivateLinkNlb:lta'
    );

    const privateLinkNlb = new elbv2.NetworkLoadBalancer(
      this,
      `${config.environment}-rdsPrivateLinkNlb`,
      {
        loadBalancerName: `${config.environment}-rdsPrivateLinkNlb`,
        vpc: vpc,
        internetFacing: false,
        crossZoneEnabled: true,
        vpcSubnets: {
          subnets: vpc.privateSubnets,
        },
        securityGroups: [privateLinkNlbSecurityGroup],
        enforceSecurityGroupInboundRulesOnPrivateLinkTraffic: false,
      }
    );

    const privateLinkTargetGroup = new elbv2.NetworkTargetGroup(
      this,
      `${config.environment}-rdsPrivateLinkTG`,
      {
        targetGroupName: `${config.environment}-rdsPrivateLinkTG`,
        vpc: vpc,
        port: auroraCluster.clusterEndpoint.port,
        protocol: elbv2.Protocol.TCP,
        targetType: elbv2.TargetType.IP,
        healthCheck: {
          interval: cdk.Duration.seconds(10),
          port: auroraCluster.clusterEndpoint.port.toString(),
          protocol: elbv2.Protocol.TCP,
          healthyThresholdCount: 3,
          timeout: cdk.Duration.seconds(10),
        },
        deregistrationDelay: cdk.Duration.seconds(0),
      }
    );

    const privateLinkNlbManagementLambdaRole = new iam.Role(
      this,
      `${config.environment}-nlbManagementLambdaRole`,
      {
        roleName: `${config.environment}-nlbManagementLambdaRole`,
        assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName(
            'service-role/AWSLambdaBasicExecutionRole'
          ),
          new iam.ManagedPolicy(this, 'rdsPrivateLinkNlbManagementPolicy', {
            description: 'Allows management of NLB for RDS private link setup',
            statements: [
              new iam.PolicyStatement({
                effect: iam.Effect.ALLOW,
                sid: 'DescribeTargetHealth',
                actions: ['elasticloadbalancing:DescribeTargetHealth'],
                resources: ['*'],
              }),
              new iam.PolicyStatement({
                effect: iam.Effect.ALLOW,
                sid: 'TargetRegistration',
                actions: [
                  'elasticloadbalancing:RegisterTargets',
                  'elasticloadbalancing:DeregisterTargets',
                ],
                resources: [privateLinkTargetGroup.targetGroupArn],
              }),
            ],
          }),
        ],
      }
    );

    privateLinkNlb.addListener(`${config.environment}-rdsPrivateLinkNlbListener`, {
      port: auroraCluster.clusterEndpoint.port,
      protocol: elbv2.Protocol.TCP,
      defaultAction: elbv2.NetworkListenerAction.forward([privateLinkTargetGroup]),
    });

    const privateLinkNlbManagementLambda = new lambda.Function(
      this,
      `${config.environment}-privateLinkNlbManagementLambda`,
      {
        functionName: `${config.environment}-privateLinkNlbManagementLambda`,
        code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/nlbUpdateLambda')),
        handler: 'index.handler',
        runtime: lambda.Runtime.PYTHON_3_12,
        role: privateLinkNlbManagementLambdaRole,
      }
    );

    privateLinkNlbManagementLambda.addEnvironment(
      'TARGET_GROUP_ARN',
      privateLinkTargetGroup.targetGroupArn
    );
    privateLinkNlbManagementLambda.addEnvironment(
      'RDS_ENDPOINT',
      auroraCluster.clusterEndpoint.hostname
    );

    privateLinkNlbManagementLambda.addEnvironment(
      'RDS_PORT',
      auroraCluster.clusterEndpoint.port.toString()
    );

    const auroraClusterFailoverSnsTopic = new sns.Topic(
      this,
      `${config.environment}-ovara-aurora-cluster-failover`,
      {
        displayName: `${config.environment}-ovara-aurora-cluster-failover`,
        topicName: `${config.environment}-ovara-aurora-cluster-failover`,
      }
    );

    new rds.CfnEventSubscription(
      this,
      `${config.environment}-ovara-aurora-cluster-failover-subscription`,
      {
        subscriptionName: `${config.environment}-ovara-aurora-cluster-failover-subscription`,
        snsTopicArn: auroraClusterFailoverSnsTopic.topicArn,
        eventCategories: [
          'failover',
          'migration',
          'failure',
          'notification',
          'serverless',
          'creation',
          'deletion',
          'maintenance',
          'configuration change',
          'global-failover',
        ],
        sourceIds: [auroraCluster.clusterIdentifier],
        sourceType: 'db-cluster',
      }
    );

    new rds.CfnEventSubscription(
      this,
      `${config.environment}-ovara-aurora-instances-failover-subscription`,
      {
        subscriptionName: `${config.environment}-ovara-aurora-instances-failover-subscription`,
        snsTopicArn: auroraClusterFailoverSnsTopic.topicArn,
        eventCategories: [
          'backup',
          'deletion',
          'availability',
          'creation',
          'low storage',
          'restoration',
          'configuration change',
          'failover',
          'maintenance',
          'failure',
          'notification',
          'read replica',
          'recovery',
          'security',
          'backtrack',
          'security patching',
        ],
        sourceIds: [...auroraCluster.instanceIdentifiers],
        sourceType: 'db-instance',
      }
    );

    auroraClusterFailoverSnsTopic.addSubscription(
      new snsSubscriptions.LambdaSubscription(privateLinkNlbManagementLambda)
    );

    const opintopolkuAccountId = ssm.StringParameter.valueForStringParameter(
      this,
      `/${config.environment}/opintopolku-account-id`
    );

    const privateLinkVpcEndpointService = new ec2.VpcEndpointService(
      this,
      `${config.environment}-rdsPrivateLinkVpcEndpointService`,
      {
        vpcEndpointServiceLoadBalancers: [privateLinkNlb],
        acceptanceRequired: false,
        allowedPrincipals: [
          new iam.ArnPrincipal(`arn:aws:iam::${opintopolkuAccountId}:root`),
        ],
      }
    );

    new route53.VpcEndpointServiceDomainName(
      this,
      `${config.environment}-privateLinkVpcEndpointServiceDomain`,
      {
        endpointService: privateLinkVpcEndpointService,
        publicHostedZone: publicHostedZone,
        domainName: `rds-privatelink.${publicHostedZone.zoneName}`,
      }
    );

    // Varmuuskopiot

    const databaseBackupRole = new iam.Role(
      this,
      `${config.environment}-ovara-database-backup-role`,
      {
        assumedBy: new iam.ServicePrincipal('backup.amazonaws.com'),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName(
            'service-role/AWSBackupServiceRolePolicyForBackup'
          ),
          iam.ManagedPolicy.fromAwsManagedPolicyName(
            'service-role/AWSBackupServiceRolePolicyForRestores'
          ),
        ],
      }
    );

    const backupPlan = new backup.BackupPlan(this, 'BackupPlan', {
      backupPlanName: `${config.environment}-ovara-backup-plan`,
      backupVault: new backup.BackupVault(this, `${config.environment}-BackupVault`, {
        backupVaultName: `${config.environment}-ovara-backup-vault`,
      }),
      backupPlanRules: [
        new backup.BackupPlanRule({
          ruleName: `${config.environment}-jatkuva-backup-rule`,
          enableContinuousBackup: true,
          deleteAfter: cdk.Duration.days(config.aurora.backup.deleteAfterDays),
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
      role: databaseBackupRole,
    });

    new cdk.CfnOutput(this, `${config.environment}-PostgresEndpoint`, {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-db-dns`,
      description: 'Aurora endpoint',
      value: `raportointi.db.${config.publicHostedZone}`,
    });

    // Valvonnat

    const cpuThreshold = 95;
    const databaseCPUUtilizationAlarm = new cloudwatch.Alarm(
      this,
      `${config.environment}-ovara-aurora-cpu-utilization-alarm`,
      {
        alarmName: `${config.environment}-ovara-aurora-cpu-utilization-alarm`,
        alarmDescription: `Ovaran Aurora-tietokannan CPUUtilization-arvo on ylittänyt hälytysrajan: ${cpuThreshold}%`,
        metric: new cloudwatch.Metric({
          metricName: 'CPUUtilization',
          namespace: 'AWS/RDS',
          period: cdk.Duration.minutes(15),
          unit: cloudwatch.Unit.PERCENT,
          statistic: cloudwatch.Stats.AVERAGE,
          dimensionsMap: {
            DBClusterIdentifier: auroraCluster.clusterIdentifier,
          },
        }),
        threshold: cpuThreshold,
        evaluationPeriods: 1,
        datapointsToAlarm: 1,
      }
    );
    addActionsToAlarm(databaseCPUUtilizationAlarm);

    this.lampiTiedostoKasiteltyTable = new dynamodb.TableV2(
      this,
      'lampiSiirtotiedostoKasitelty',
      {
        tableName: 'lampiSiirtotiedostoKasitelty',
        partitionKey: {
          name: 'tiedostotyyppi',
          type: dynamodb.AttributeType.STRING,
        },
      }
    );

    cdkNag.NagSuppressions.addStackSuppressions(this, [
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
