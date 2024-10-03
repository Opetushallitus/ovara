import * as cdk from 'aws-cdk-lib';
import * as appscaling from 'aws-cdk-lib/aws-applicationautoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface EcsStackProps extends GenericStackProps {
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

    const dbtFargateTaskName = `${config.environment}-dbt-task`;

    const dbtTaskLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${dbtFargateTaskName}LogGroup`,
      {
        logGroupName: `/aws/ecs/${dbtFargateTaskName}`,
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

    const scheduledFargateTask = new ecsPatterns.ScheduledFargateTask(
      this,
      dbtFargateTaskName,
      {
        ruleName: `${config.environment}`,
        cluster: ecsCluster,
        scheduledFargateTaskImageOptions: {
          image: ecs.ContainerImage.fromRegistry('amazon/amazon-ecs-sample'),
          logDriver: logDriver,
          memoryLimitMiB: 512,
        },
        schedule: appscaling.Schedule.expression('rate(5 minutes)'),
        securityGroups: [ecsSecurityGroup],
        tags: [],
      }
    );

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM5', reason: "Can't fix this." },
    ]);
  }
}
