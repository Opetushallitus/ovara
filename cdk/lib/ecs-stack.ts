import * as cdk from 'aws-cdk-lib';
import * as appscaling from 'aws-cdk-lib/aws-applicationautoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Effect } from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface EcsStackProps extends GenericStackProps {
  auroraSecurityGroup: ec2.ISecurityGroup;
  ecsImageTag: string;
  vpc: ec2.IVpc;
}

export class EcsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: EcsStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

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

    const dbtRunnerImage = ecs.ContainerImage.fromEcrRepository(
      dbtRunnerRepository,
      props.ecsImageTag
      //'ga-6'
    );

    const schedule = appscaling.Schedule.cron({
      minute: '30',
      hour: '*',
      day: '*',
      month: '*',
      year: '*',
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
          memoryLimitMiB: 512,
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
        tags: [],
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

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: "Can't fix this." },
      { id: 'AwsSolutions-ECS2', reason: 'Static environment variables' },
    ]);
  }
}
