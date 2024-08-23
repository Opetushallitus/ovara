import * as cdk from 'aws-cdk-lib';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import * as slack from 'cdk-slack-chatbot';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export class MonitorStack extends cdk.Stack {
  public readonly slackAlarmIntegrationSnsTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: GenericStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const slackAlarmIntegration = new slack.CdkSlackChatBot(
      this,
      `${config.environment}-slack-alarm-integration`,
      {
        topicName: `${config.environment}-slack-alarm`,
        slackChannelId: ssm.StringParameter.valueForStringParameter(
          this,
          `/${config.environment}/monitor/slack-alarm-integration-channel-id`
        ),
        slackWorkSpaceId: ssm.StringParameter.valueForStringParameter(
          this,
          `/${config.environment}/monitor/slack-alarm-integration-workspace-id`
        ),
        slackChannelConfigName: `${config.environment}-slack-valvonta`,
      }
    );

    this.slackAlarmIntegrationSnsTopic = slackAlarmIntegration.topic;

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-SNS2', reason: 'Not needed with Alarm sending' },
      { id: 'AwsSolutions-SNS3', reason: 'Not needed with Alarm sending' },
    ]);
  }
}
