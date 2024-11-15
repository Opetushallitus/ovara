import * as cdk from 'aws-cdk-lib';
import * as appscaling from 'aws-cdk-lib/aws-applicationautoscaling';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import { CfnRule } from 'aws-cdk-lib/aws-events';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Effect } from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface EcsStackProps extends GenericStackProps {
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

    const dbtFargateTaskName = `${config.environment}-dbt-task`;

    const dbtTaskLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${dbtFargateTaskName}LogGroup`,
      {
        logGroupName: `/aws/ecs/task/${dbtFargateTaskName}`,
      }
    );

    const logDriver = new ecs.AwsLogDriver({
      logGroup: dbtTaskLogGroup,
      streamPrefix: 'dbt-runner-app',
    });

    const ecsClusterName = `${config.environment}-ecs-cluster`;
    const ecsCluster = new ecs.Cluster(this, ecsClusterName, {
      clusterName: ecsClusterName,
      containerInsights: true,
      vpc: props.vpc,
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

    const imageVersion =
      props.ecsImageTag !== undefined && props.ecsImageTag !== ''
        ? props.ecsImageTag
        : ssm.StringParameter.valueForStringParameter(
            this,
            `/${config.environment}/ecs/dbt-runner/version`
          );

    const dbtRunnerImage = ecs.ContainerImage.fromEcrRepository(
      dbtRunnerRepository,
      imageVersion
    );

    const schedule = appscaling.Schedule.cron({
      minute: '30',
      hour: '0-23/1',
    });
    const scheduledFargateTask = new ecsPatterns.ScheduledFargateTask(
      this,
      dbtFargateTaskName,
      {
        ruleName: `${config.environment}-scheduledFargateTaskRule`,
        cluster: ecsCluster,
        scheduledFargateTaskImageOptions: {
          image: dbtRunnerImage,
          logDriver: logDriver,
          cpu: 1024,
          memoryLimitMiB: 2048,
          environment: {
            POSTGRES_HOST_PROD: `raportointi.db.${config.publicHostedZone}`,
            DBT_PORT_PROD: '5432',
            DBT_USERNAME_PROD: 'app',
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
        //schedule: appscaling.Schedule.expression('rate(5 minutes)'),
        schedule: schedule,
        securityGroups: [ecsSecurityGroup],
        enabled: true,
      }
    );

    scheduledFargateTask.taskDefinition.addToExecutionRolePolicy(
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

    scheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantAssumeRole(props.githubActionsDeploymentRole);

    scheduledFargateTask.taskDefinition
      .obtainExecutionRole()
      .grantPassRole(props.githubActionsDeploymentRole);

    const eventsRule = scheduledFargateTask.eventRule.node.defaultChild as CfnRule;

    const eventsRole = new iam.Role(this, 'EventsRole', {
      assumedBy: new iam.ServicePrincipal('events.amazonaws.com'),
    });

    eventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:RunTask'],
        conditions: {
          ArnEquals: {
            'ecs:cluster': ecsCluster.clusterArn,
          },
        },
        resources: [
          scheduledFargateTask.taskDefinition.taskDefinitionArn.substring(
            0,
            scheduledFargateTask.taskDefinition.taskDefinitionArn.lastIndexOf(':') + 1
          ) + '*',
        ],
      })
    );

    eventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['ecs:TagResource'],
        resources: [`arn:aws:ecs:${this.region}:*:task/${ecsClusterName}/*`],
      })
    );

    eventsRole.addToPolicy(
      new iam.PolicyStatement({
        actions: ['iam:PassRole'],
        resources: [
          scheduledFargateTask.taskDefinition.taskRole.roleArn,
          scheduledFargateTask.taskDefinition.executionRole!.roleArn,
        ],
      })
    );

    eventsRule.targets = [
      {
        arn: ecsCluster.clusterArn,
        id: 'Target0',
        roleArn: eventsRole.roleArn,
        ecsParameters: {
          launchType: 'FARGATE',
          taskCount: 1,
          taskDefinitionArn: scheduledFargateTask.taskDefinition.taskDefinitionArn,
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

    const ovaraCustomMetricsNamespace = `${config.environment}-OvaraCustomMetrics`;
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

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: "Can't fix this." },
      { id: 'AwsSolutions-ECS2', reason: 'Static environment variables' },
    ]);
  }
}
