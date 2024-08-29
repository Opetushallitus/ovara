import * as path from 'path';

import * as cdk from 'aws-cdk-lib';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as cr from 'aws-cdk-lib/custom-resources';
//import * as sns_subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
//import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface DatabaseStackProps extends GenericStackProps {
  publicHostedZone: route53.IHostedZone;
  vpc: ec2.IVpc;
  slackAlarmIntegrationSnsTopic: sns.ITopic;
}

export class DatabaseStack extends cdk.Stack {
  public readonly auroraSecurityGroup: ec2.ISecurityGroup;

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

    const rdsProxySecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-ovaraAuroraRdsProxySecurityGroup`,
      {
        securityGroupName: `${config.environment}-ovara-aurora-rds-proxy`,
        vpc: vpc,
      }
    );
    rdsProxySecurityGroup.addIngressRule(rdsProxySecurityGroup, ec2.Port.tcp(5432));

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
        // TODO: lisää reader instanssi
        vpc,
        vpcSubnets: {
          subnets: vpc.privateSubnets,
        },
        securityGroups: [this.auroraSecurityGroup, rdsProxySecurityGroup],
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
        backup: {
          retention: cdk.Duration.days(config.aurora.backup.deleteAfterDays),
        },
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

    // RDS Proxy

    const opintopolkuProxyUserSecret = new secretsmanager.Secret(
      this,
      `${config.environment}-ovara-aurora-cluster-opintopolku-proxy-secret`,
      {
        generateSecretString: {
          secretStringTemplate: JSON.stringify({
            username: 'opintopolku',
          }),
          generateStringKey: 'password',
          excludePunctuation: true,
          includeSpace: false,
        },
      }
    );

    const rdsProxy = auroraCluster.addProxy(`${config.environment}-OvaraAuroraRDSProxy`, {
      secrets: [opintopolkuProxyUserSecret],
      vpc: vpc,
      vpcSubnets: {
        subnets: vpc.privateSubnets,
      },
      debugLogging: true,
      borrowTimeout: cdk.Duration.seconds(30),
      securityGroups: [rdsProxySecurityGroup],
    });

    // PrivateLink

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
      }
    );

    const privateLinkNlbAccessLogsBucketName = `${config.environment}-privatelink-nlb-access-logs`;
    const privateLinkNlbAccessLogsBucket = new s3.Bucket(
      this,
      privateLinkNlbAccessLogsBucketName,
      {
        objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
        blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
        encryptionKey: new kms.Key(
          this,
          `${privateLinkNlbAccessLogsBucketName}-s3BucketKMSKey`,
          {
            enableKeyRotation: true,
          }
        ),
        serverAccessLogsBucket: new s3.Bucket(
          this,
          `${privateLinkNlbAccessLogsBucketName}-server-access-logs`
        ),
      }
    );

    privateLinkNlb.logAccessLogs(privateLinkNlbAccessLogsBucket);

    const privateLinkTargetGroup = new elbv2.NetworkTargetGroup(
      this,
      `${config.environment}-rdsPrivateLinkTargetGroup`,
      {
        targetGroupName: `${config.environment}-rdsPrivateLinkTargetGroup`,
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
      port: 5432,
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
    privateLinkNlbManagementLambda.addEnvironment('RDS_ENDPOINT', rdsProxy.endpoint);
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
        eventCategories: ['failover', 'failure'],
        sourceIds: [auroraCluster.clusterIdentifier],
        sourceType: 'db-cluster',
      }
    );

    const privateLinkVpcEndpointService = new ec2.VpcEndpointService(
      this,
      `${config.environment}-rdsPrivateLinkVpcEndpointService`,
      {
        vpcEndpointServiceLoadBalancers: [privateLinkNlb],
        acceptanceRequired: false,
        allowedPrincipals: [],
      }
    );

    new cr.AwsCustomResource(this, `${config.environment}-PrivateLinkTagging`, {
      functionName: `${config.environment}-PrivateLinkTagging`,
      onUpdate: {
        action: 'createTags',
        parameters: {
          Resources: [privateLinkVpcEndpointService.vpcEndpointServiceId],
          Tags: this.tags.renderedTags,
        },
        service: 'EC2',
        physicalResourceId: cr.PhysicalResourceId.of('rdsPrivateLinkTagging'),
      },
      policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
        resources: [
          `arn:aws:ec2:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:vpc-endpoint-service/${privateLinkVpcEndpointService.vpcEndpointServiceId}`,
        ],
      }),
    });

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

    const acuThreshold = 90;
    const databaseACUUtilizationAlarm = new cloudwatch.Alarm(
      this,
      `${config.environment}-ovara-aurora-acu-utilization-alarm`,
      {
        alarmName: `${config.environment}-ovara-aurora-acu-utilization-alarm`,
        alarmDescription: `Ovaran Aurora-tietokannan ACUUtilization-arvo on ylittänyt hälytysrajan: ${acuThreshold}%`,
        metric: new cloudwatch.Metric({
          metricName: 'ACUUtilization',
          namespace: 'AWS/RDS',
          period: cdk.Duration.minutes(15),
          unit: cloudwatch.Unit.PERCENT,
          statistic: cloudwatch.Stats.AVERAGE,
          dimensionsMap: {
            DBClusterIdentifier: auroraCluster.clusterIdentifier,
          },
        }),
        threshold: acuThreshold,
        evaluationPeriods: 1,
        datapointsToAlarm: 1,
      }
    );
    addActionsToAlarm(databaseACUUtilizationAlarm);

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
    ]);
  }
}
