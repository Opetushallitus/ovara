import * as cdk from 'aws-cdk-lib';
import * as chatbot from 'aws-cdk-lib/aws-chatbot';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export class MonitorStack extends cdk.Stack {
  public readonly slackAlarmIntegrationSnsTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: GenericStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const slackAlarmIntegrationSnsTopic = new sns.Topic(
      this,
      `${config.environment}-slack-alarm`,
      {
        displayName: `${config.environment}-slack-alarm`,
        topicName: `${config.environment}-slack-alarm`,
      }
    );

    this.slackAlarmIntegrationSnsTopic = slackAlarmIntegrationSnsTopic;

    new chatbot.SlackChannelConfiguration(this, `${config.environment}-slack-valvonta`, {
      slackChannelConfigurationName: `${config.environment}-slack-valvonta`,
      slackWorkspaceId: ssm.StringParameter.valueForStringParameter(
        this,
        `/${config.environment}/monitor/slack-alarm-integration-workspace-id`
      ),
      slackChannelId: ssm.StringParameter.valueForStringParameter(
        this,
        `/${config.environment}/monitor/slack-alarm-integration-channel-id`
      ),
      notificationTopics: [slackAlarmIntegrationSnsTopic],
      loggingLevel: chatbot.LoggingLevel.INFO,
      logRetention: logs.RetentionDays.THREE_MONTHS,
    });

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-SNS2', reason: 'Not needed with Alarm sending' },
      { id: 'AwsSolutions-SNS3', reason: 'Not needed with Alarm sending' },
      { id: 'AwsSolutions-IAM4', reason: 'Ignoring this for now' },
      { id: 'AwsSolutions-IAM5', reason: 'Ignoring this for now' },
    ]);
  }
}
