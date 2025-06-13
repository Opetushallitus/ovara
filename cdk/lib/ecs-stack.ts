import * as cdk from 'aws-cdk-lib';
import { Duration } from 'aws-cdk-lib';
import * as appscaling from 'aws-cdk-lib/aws-applicationautoscaling';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import { ContainerInsights } from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import { CfnRule } from 'aws-cdk-lib/aws-events';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Effect } from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface EcsStackProps extends GenericStackProps {
  auroraCluster: rds.IDatabaseCluster;
  auroraSecurityGroup: ec2.ISecurityGroup;
  ecsImageTag: string;
  githubActionsDeploymentRole: iam.IRole;
  slackAlarmIntegrationSnsTopic: sns.ITopic;
  vpc: ec2.IVpc;
}

export class EcsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: EcsStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const ecsProsessiOnKaynnissaTable = new dynamodb.TableV2(
      this,
      'ecsProsessiOnKaynnissa',
      {
        tableName: 'ecsProsessiOnKaynnissa',
        partitionKey: {
          name: 'prosessi',
          type: dynamodb.AttributeType.STRING,
        },
      }
    );

    const addActionsToAlarm = (alarm: cloudwatch.Alarm) => {
      alarm.addAlarmAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
    };

    const ecsSecurityGroupName = `${config.environment}-ovara-ecs-sg`;
    const ecsSecurityGroup = new ec2.SecurityGroup(this, ecsSecurityGroupName, {
      securityGroupName: ecsSecurityGroupName,
      vpc: props.vpc,
      allowAllOutbound: true,
    });

    props.auroraSecurityGroup.addIngressRule(
      ecsSecurityGroup,
      ec2.Port.tcp(5432),
      'ECS-konteille paasy tietokantaan'
    );

    const ecsClusterName = `${config.environment}-ecs-cluster`;
    const ecsCluster = new ecs.Cluster(this, ecsClusterName, {
      clusterName: ecsClusterName,
      containerInsightsV2: ContainerInsights.ENABLED,
      vpc: props.vpc,
    });

    const ovaraCustomMetricsNamespace = `${config.environment}-OvaraCustomMetrics`;

    /* DBT Runner starts */

    const dbtFargateTaskName = `${config.environment}-dbt-task`;

    const dbtTaskLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${dbtFargateTaskName}LogGroup`,
      {
        logGroupName: `/aws/ecs/task/${dbtFargateTaskName}`,
      }
    );

    const dbtRunnerLogDriver = new ecs.AwsLogDriver({
      logGroup: dbtTaskLogGroup,
      streamPrefix: 'dbt-runner-app',
    });

    const dbtRunnerRepositoryName = 'ovara-dbt-runner';
    const dbtRunnerRepository = ecr.Repository.fromRepositoryAttributes(
      this,
      dbtRunnerRepositoryName,
      {
        repositoryArn: ssm.StringParameter.valueForStringParameter(
          this,
          `/${config.environment}/ovara-utility-ovara-dbt-runner-repository-arn`
        ),
        repositoryName: dbtRunnerRepositoryName,
      }
    );

    const dbtRunnerImageVersion =
      props.ecsImageTag !== undefined && props.ecsImageTag !== ''
        ? props.ecsImageTag
        : ssm.StringParameter.valueForStringParameter(
            this,
            `/${config.environment}/ecs/dbt-runner/version`
          );

    const dbtRunnerImage = ecs.ContainerImage.fromEcrRepository(
      dbtRunnerRepository,
      dbtRunnerImageVersion
    );

    const ovaraDokumentaatioBucket = s3.Bucket.fromBucketName(
      this,
      `${config.environment}-ovara-dokumentaatio`,
      `${config.environment}-ovara-dokumentaatio`
    );
    const dbtLogsBucket = new s3.Bucket(this, `${config.environment}-dbt-logs`, {
      bucketName: `${config.environment}-dbt-logs`,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${config.environment}-dbt-logs-bucket-server-access-logs`
      ),
      versioned: false,
    });

    const dbtRunnerSchedule = appscaling.Schedule.cron(config.dbtCron);
    const dbtProcessingEnabled = config.dbtProcessingEnabled?.toLowerCase() === 'true';
    const dbtRunnerScheduledFargateTask = new ecsPatterns.ScheduledFargateTask(
      this,
      dbtFargateTaskName,
      {
        ruleName: `${config.environment}-scheduledFargateTaskRule`,
        cluster: ecsCluster,
        scheduledFargateTaskImageOptions: {
          image: dbtRunnerImage,
          logDriver: dbtRunnerLogDriver,
          cpu: 1024,
          memoryLimitMiB: 2048,
          environment: {
            POSTGRES_HOST_PROD: `raportointi.db.${config.publicHostedZone}`,
            DBT_PORT_PROD: '5432',
            DBT_USERNAME_PROD: 'app',
            OVARA_DOC_BUCKET: ovaraDokumentaatioBucket.bucketName,
            DBT_LOGS_BUCKET: dbtLogsBucket.bucketName,
          },
          secrets: {
            DBT_PASSWORD_PROD: ecs.Secret.fromSsmParameter(
              ssm.StringParameter.fromSecureStringParameterAttributes(
                this,
                `${config.environment}-auroraAppPassword`,
                {
                  parameterName: `/${config.environment}/aurora/raportointi/app-user-password`,
                }
              )
            ),
          },
        },
        schedule: dbtRunnerSchedule,
        securityGroups: [ecsSecurityGroup],
        enabled: dbtProcessingEnabled,
      }
    );

    dbtRunnerScheduledFargateTask.taskDefinition.addToExecutionRolePolicy(
      new iam.PolicyStatement({
        actions: [
          'ecr:GetAuthorizationToken',
          'ecr:BatchCheckLayerAvailability',
          'ecr:GetDownloadUrlForLayer',
          'ecr:BatchGetImage',
        ],
        effect: Effect.ALLOW,
        resources: ['*'],
      })
    );

    ovaraDokumentaatioBucket.grantReadWrite(
      dbtRunnerScheduledFargateTask.taskDefinition.taskRole
    );
    dbtLogsBucket.grantReadWrite(dbtRunnerScheduledFargateTask.taskDefinition.taskRole);
    ecsProsessiOnKaynnissaTable.grant(
      dbtRunnerScheduledFargateTask.taskDefinition.taskRole,
      ...['dynamodb:PartiQLSelect', 'dynamodb:PartiQLUpdate']
    );

    dbtRunnerScheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantAssumeRole(props.githubActionsDeploymentRole);

    dbtRunnerScheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantPassRole(props.githubActionsDeploymentRole);

    const dbtRunnerEventsRule = dbtRunnerScheduledFargateTask.eventRule.node
      .defaultChild as CfnRule;

    const dbtRunnerEventsRole = new iam.Role(this, 'EventsRole', {
      assumedBy: new iam.ServicePrincipal('events.amazonaws.com'),
    });

    dbtRunnerEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:RunTask'],
        conditions: {
          ArnEquals: {
            'ecs:cluster': ecsCluster.clusterArn,
          },
        },
        resources: [
          dbtRunnerScheduledFargateTask.taskDefinition.taskDefinitionArn.substring(
            0,
            dbtRunnerScheduledFargateTask.taskDefinition.taskDefinitionArn.lastIndexOf(
              ':'
            ) + 1
          ) + '*',
        ],
      })
    );

    dbtRunnerEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:TagResource'],
        resources: [`arn:aws:ecs:${this.region}:*:task/${ecsClusterName}/*`],
      })
    );

    dbtRunnerEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['iam:PassRole'],
        resources: [
          dbtRunnerScheduledFargateTask.taskDefinition.taskRole.roleArn,
          dbtRunnerScheduledFargateTask.taskDefinition.executionRole!.roleArn,
        ],
      })
    );

    dbtRunnerEventsRule.targets = [
      {
        arn: ecsCluster.clusterArn,
        id: 'Target0',
        roleArn: dbtRunnerEventsRole.roleArn,
        ecsParameters: {
          launchType: 'FARGATE',
          taskCount: 1,
          taskDefinitionArn:
            dbtRunnerScheduledFargateTask.taskDefinition.taskDefinitionArn,
          networkConfiguration: {
            awsVpcConfiguration: {
              securityGroups: [ecsSecurityGroup.securityGroupId],
              subnets: [
                props.vpc.selectSubnets({
                  subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
                }).subnets[0].subnetId,
                props.vpc.selectSubnets({
                  subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
                }).subnets[1].subnetId,
              ],
              assignPublicIp: 'DISABLED',
            },
          },
        },
      },
    ];

    // Metriikat ja hälytykset

    const dbtRunnerFailedErrorMetricName = 'DbtRunnerFailedError';
    const dbtRunnerKestoMetricName = 'DbtRunnerKesto';

    const dbtRunnerFailedErrorMetric = new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: dbtRunnerFailedErrorMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.NONE,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(
      this,
      `${config.environment}-dbtRunnerFailedErrorMetricFilter`,
      {
        filterPattern: logs.FilterPattern.literal('"Done. PASS" -"ERROR=0"'),
        logGroup: dbtTaskLogGroup,
        metricName: dbtRunnerFailedErrorMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
      }
    );

    const dbtRunnerFailedErrorAlarm = new cloudwatch.Alarm(this, 'AlarmId', {
      metric: dbtRunnerFailedErrorMetric,
      evaluationPeriods: 3,
      datapointsToAlarm: 1,
      alarmName: `${config.environment}-ovara-DbtRunnerFailedError`,
      alarmDescription: 'DBT-ajossa tapahtui virhe',
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      threshold: 0,
    });
    addActionsToAlarm(dbtRunnerFailedErrorAlarm);

    new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: dbtRunnerKestoMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.SECONDS,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(this, `${config.environment}-dbtRunnerKestMetricFilter`, {
      filterPattern: logs.FilterPattern.spaceDelimited('text1', 'text2', 'kesto', 'text3')
        .whereString('text1', '=', 'Ajon')
        .whereString('text2', '=', 'kesto')
        .whereString('text3', '=', 's'),
      logGroup: dbtTaskLogGroup,
      metricName: dbtRunnerKestoMetricName,
      metricNamespace: ovaraCustomMetricsNamespace,
      metricValue: '$kesto',
    });

    /* DBT Runner ends */

    /* Lampi-siirtäjä starts */

    const lampiSiirtajaFargateTaskName = `${config.environment}-ovara-lampi-siirtaja`;

    const lampiSiirtajaLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${lampiSiirtajaFargateTaskName}LogGroup`,
      {
        logGroupName: `/aws/ecs/task/${lampiSiirtajaFargateTaskName}`,
      }
    );

    const lampiSiirtajaLogDriver = new ecs.AwsLogDriver({
      logGroup: lampiSiirtajaLogGroup,
      streamPrefix: 'ovara-lampi-siirtaja-app',
    });

    const lampiSiirtajaRepositoryName = 'ovara-lampi-siirtaja';
    const lampiSiirtajaRepository = ecr.Repository.fromRepositoryAttributes(
      this,
      lampiSiirtajaRepositoryName,
      {
        repositoryArn: ssm.StringParameter.valueForStringParameter(
          this,
          `/${config.environment}/ovara-utility-ovara-lampi-siirtaja-repository-arn`
        ),
        repositoryName: lampiSiirtajaRepositoryName,
      }
    );

    const lampiSiirtajaImageVersion = ssm.StringParameter.valueForStringParameter(
      this,
      `/${config.environment}/ecs/lampi-siirtaja/version`
    );

    const lampiSiirtajaImage = ecs.ContainerImage.fromEcrRepository(
      lampiSiirtajaRepository,
      lampiSiirtajaImageVersion
    );

    // Tilapäinen S3-ämpäri testausta varten
    const lampiSiirtajaTempS3Bucket = new s3.Bucket(
      this,
      `${config.environment}-temp-lampi-siirtaja-bucket`,
      {
        bucketName: `${config.environment}-temp-lampi-siirtaja-bucket`,
        objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
        blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
        serverAccessLogsBucket: new s3.Bucket(
          this,
          `${config.environment}-temp-lampi-siirtaja-bucket-server-access-logs`
        ),
        versioned: false,
      }
    );

    lampiSiirtajaTempS3Bucket.addLifecycleRule({
      abortIncompleteMultipartUploadAfter: Duration.days(1),
      enabled: true,
      expiration: Duration.days(2),
      id: 'rule',
    });

    const lampiSiirtajaS3Bucket = new s3.Bucket(
      this,
      `${config.environment}-lampi-siirtaja-bucket`,
      {
        bucketName: `${config.environment}-lampi-siirtaja-bucket`,
        objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
        blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
        serverAccessLogsBucket: new s3.Bucket(
          this,
          `${config.environment}-lampi-siirtaja-bucket-server-access-logs`
        ),
        versioned: false,
      }
    );

    lampiSiirtajaS3Bucket.addLifecycleRule({
      abortIncompleteMultipartUploadAfter: Duration.days(1),
      enabled: true,
      expiration: Duration.days(14),
      id: 'rule',
    });

    const rdsExportPolicy = new iam.ManagedPolicy(
      this,
      `${config.environment}-ovara-aurora-export-policy`,
      {
        statements: [
          new iam.PolicyStatement({
            sid: `${config.environment}OvaraAuroraExportExport`,
            effect: Effect.ALLOW,
            actions: ['s3:PutObject', 's3:AbortMultipartUpload'],
            resources: [
              lampiSiirtajaS3Bucket.bucketArn,
              lampiSiirtajaS3Bucket.arnForObjects('*'),
            ],
          }),
        ],
      }
    );

    const rdsExportRole = new iam.Role(
      this,
      `${config.environment}-ovara-aurora-export-role`,
      {
        assumedBy: new iam.ServicePrincipal('rds.amazonaws.com'),
        managedPolicies: [rdsExportPolicy],
      }
    );

    const cfnDbCluster = props.auroraCluster.node.defaultChild as rds.CfnDBCluster;
    cfnDbCluster.associatedRoles = [
      {
        featureName: 's3Export',
        roleArn: rdsExportRole.roleArn,
      },
    ];

    const lampiSiirtajaSchedule = appscaling.Schedule.cron(config.lampiSiirtajaCron);
    const lampiSiirtajaEnabled = config.lampiSiirtajaEnabled?.toLowerCase() === 'true';
    const lampiSiirtajaScheduledFargateTask = new ecsPatterns.ScheduledFargateTask(
      this,
      lampiSiirtajaFargateTaskName,
      {
        ruleName: `${config.environment}-lampiSiirtajaScheduledFargateTaskRule`,
        cluster: ecsCluster,
        scheduledFargateTaskImageOptions: {
          image: lampiSiirtajaImage,
          logDriver: lampiSiirtajaLogDriver,
          cpu: 2048,
          memoryLimitMiB: 6144,
          environment: {
            POSTGRES_HOST: `raportointi.db.${config.publicHostedZone}`,
            POSTGRES_PORT: '5432',
            DB_USERNAME: 'app',
            //LAMPI_S3_BUCKET: lampiSiirtajaTempS3Bucket.bucketName,
            LAMPI_S3_BUCKET: config.siirtotiedostot.lampiBucketName,
            OVARA_LAMPI_SIIRTAJA_BUCKET: lampiSiirtajaS3Bucket.bucketName,
            LAMPI_ROLE_ARN: ssm.StringParameter.valueForStringParameter(
              this,
              `/${config.environment}/lampi-write-role`
            ),
            LAMPI_ROLE_SESSION_NAME: 'ovara-lampi-export',
            LAMPI_EXTERNAL_ID: ssm.StringParameter.valueForStringParameter(
              this,
              `/${config.environment}/lampi-external-id`
            ),
          },
          secrets: {
            DB_PASSWORD: ecs.Secret.fromSsmParameter(
              ssm.StringParameter.fromSecureStringParameterAttributes(
                this,
                `${config.environment}-lampiSiirtajaauroraAppPassword`,
                {
                  parameterName: `/${config.environment}/aurora/raportointi/app-user-password`,
                }
              )
            ),
          },
        },
        schedule: lampiSiirtajaSchedule,
        securityGroups: [ecsSecurityGroup],
        enabled: lampiSiirtajaEnabled,
      }
    );

    lampiSiirtajaScheduledFargateTask.taskDefinition.addToTaskRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['sts:AssumeRole'],
        resources: [
          ssm.StringParameter.valueForStringParameter(
            this,
            `/${config.environment}/lampi-write-role`
          ),
        ],
      })
    );

    lampiSiirtajaTempS3Bucket.grantReadWrite(
      lampiSiirtajaScheduledFargateTask.taskDefinition.taskRole
    );

    lampiSiirtajaS3Bucket.grantReadWrite(
      lampiSiirtajaScheduledFargateTask.taskDefinition.taskRole
    );

    ecsProsessiOnKaynnissaTable.grant(
      lampiSiirtajaScheduledFargateTask.taskDefinition.taskRole,
      ...['dynamodb:PartiQLSelect', 'dynamodb:PartiQLUpdate']
    );

    lampiSiirtajaScheduledFargateTask.taskDefinition.addToExecutionRolePolicy(
      new iam.PolicyStatement({
        actions: [
          'ecr:GetAuthorizationToken',
          'ecr:BatchCheckLayerAvailability',
          'ecr:GetDownloadUrlForLayer',
          'ecr:BatchGetImage',
        ],
        effect: Effect.ALLOW,
        resources: ['*'],
      })
    );

    lampiSiirtajaScheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantAssumeRole(props.githubActionsDeploymentRole);

    lampiSiirtajaScheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantPassRole(props.githubActionsDeploymentRole);

    const lampiSiirtajaEventsRule = lampiSiirtajaScheduledFargateTask.eventRule.node
      .defaultChild as CfnRule;

    const lampiSiirtajaEventsRole = new iam.Role(this, 'LampiSiirtajaEventsRole', {
      assumedBy: new iam.ServicePrincipal('events.amazonaws.com'),
    });

    lampiSiirtajaEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:RunTask'],
        conditions: {
          ArnEquals: {
            'ecs:cluster': ecsCluster.clusterArn,
          },
        },
        resources: [
          lampiSiirtajaScheduledFargateTask.taskDefinition.taskDefinitionArn.substring(
            0,
            lampiSiirtajaScheduledFargateTask.taskDefinition.taskDefinitionArn.lastIndexOf(
              ':'
            ) + 1
          ) + '*',
        ],
      })
    );

    lampiSiirtajaEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:TagResource'],
        resources: [`arn:aws:ecs:${this.region}:*:task/${ecsClusterName}/*`],
      })
    );

    lampiSiirtajaEventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['iam:PassRole'],
        resources: [
          lampiSiirtajaScheduledFargateTask.taskDefinition.taskRole.roleArn,
          lampiSiirtajaScheduledFargateTask.taskDefinition.executionRole!.roleArn,
        ],
      })
    );

    lampiSiirtajaEventsRule.targets = [
      {
        arn: ecsCluster.clusterArn,
        id: 'Target0',
        roleArn: lampiSiirtajaEventsRole.roleArn,
        ecsParameters: {
          launchType: 'FARGATE',
          taskCount: 1,
          taskDefinitionArn:
            lampiSiirtajaScheduledFargateTask.taskDefinition.taskDefinitionArn,
          networkConfiguration: {
            awsVpcConfiguration: {
              securityGroups: [ecsSecurityGroup.securityGroupId],
              subnets: [
                props.vpc.selectSubnets({
                  subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
                }).subnets[0].subnetId,
                props.vpc.selectSubnets({
                  subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
                }).subnets[1].subnetId,
              ],
              assignPublicIp: 'DISABLED',
            },
          },
        },
      },
    ];

    // Metriikat ja hälytykset

    const lampiSiirtajaFailedErrorMetricName = 'LampiSiirtajaFailedError';
    const lampiSiirtajaKestoMetricName = 'LampiSiirtajaKesto';

    const lampiSiirtajaFailedErrorMetric = new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: lampiSiirtajaFailedErrorMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.NONE,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(
      this,
      `${config.environment}-lampiSiirtajaFailedErrorMetricFilter`,
      {
        filterPattern: logs.FilterPattern.literal('?"Error" ?"ERROR" ?"error"'),
        logGroup: lampiSiirtajaLogGroup,
        metricName: lampiSiirtajaFailedErrorMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
      }
    );

    const lampiSiirtajaFailedErrorAlarm = new cloudwatch.Alarm(
      this,
      'LampiSiirtajaAlarmId',
      {
        metric: lampiSiirtajaFailedErrorMetric,
        evaluationPeriods: 3,
        datapointsToAlarm: 1,
        alarmName: `${config.environment}-ovara-LampiSiirtajaFailedError`,
        alarmDescription: 'Ovaran tietojen siirtämisessä Lampeen tapahtui virhe',
        comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
        threshold: 0,
      }
    );
    addActionsToAlarm(lampiSiirtajaFailedErrorAlarm);

    new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: lampiSiirtajaKestoMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.SECONDS,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(this, `${config.environment}-lampiSiirtajaKestoMetricFilter`, {
      filterPattern: logs.FilterPattern.spaceDelimited('text1', 'text2', 'kesto', 'text3')
        .whereString('text1', '=', 'Ajon')
        .whereString('text2', '=', 'kesto')
        .whereString('text3', '=', 's'),
      logGroup: lampiSiirtajaLogGroup,
      metricName: lampiSiirtajaKestoMetricName,
      metricNamespace: ovaraCustomMetricsNamespace,
      metricValue: '$kesto',
    });

    /* Lampi-siirtäjä ends */

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: "Can't fix this." },
      { id: 'AwsSolutions-ECS2', reason: 'Static environment variables' },
      { id: 'AwsSolutions-S10', reason: 'Tilapäinen S3-ämpäri' },
    ]);
  }
}
