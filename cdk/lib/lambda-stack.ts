import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface LambdaStackProps extends GenericStackProps {
  vpc: ec2.IVpc;
  siirtotiedostoPutEventSource: cdk.aws_lambda_event_sources.S3EventSource;
  slackAlarmIntegrationSnsTopic: sns.ITopic;
}

export class LambdaStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: LambdaStackProps) {
    super(scope, id, props);

    const config: Config = props.config;

    const addActionsToAlarm = (alarm: cloudwatch.Alarm) => {
      alarm.addAlarmAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
    };

    const lambdaSecurityGroup = new ec2.SecurityGroup(
      this,
      `${config.environment}-LambdaSecurityGroup`,
      {
        vpc: props.vpc,
        allowAllOutbound: true,
        description: 'Security group for lambda',
        securityGroupName: `${config.environment}-opiskelijavalinnanraportointi-lambda`,
      }
    );

    const auroraSecurityGroupId = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-aurora-securitygroupid`
    );

    const auroraSecurityGroup = ec2.SecurityGroup.fromSecurityGroupId(
      this,
      'PostgresSecurityGroup',
      auroraSecurityGroupId
    );

    auroraSecurityGroup.addIngressRule(
      lambdaSecurityGroup,
      ec2.Port.tcp(5432),
      'DB sallittu lambdoille'
    );

    const siirtotiedostoBucketArn = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-bucket-arn`
    );
    const siirtotiedostoBucketStatement = new iam.PolicyStatement();
    siirtotiedostoBucketStatement.addResources(siirtotiedostoBucketArn);
    siirtotiedostoBucketStatement.addActions('s3:ListBucket', 's3:ListBucketVersions');

    const siirtotiedostoBucketContentStatement = new iam.PolicyStatement();
    siirtotiedostoBucketContentStatement.addResources(`${siirtotiedostoBucketArn}/*`);
    siirtotiedostoBucketContentStatement.addActions(
      's3:GetObject',
      's3:PutObject',
      's3:GetObjectAttributes',
      's3:ListMultipartUploadParts',
      's3:AbortMultipartUpload',
      's3:PutObjectTagging'
    );
    const siirtotiedostoBucketContentDocument = new iam.PolicyDocument();
    siirtotiedostoBucketContentDocument.addStatements(
      siirtotiedostoBucketStatement,
      siirtotiedostoBucketContentStatement
    );

    const siirtotiedostoKeyArn = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-key-arn`
    );
    const siirtotiedostoKeyStatement = new iam.PolicyStatement();
    siirtotiedostoKeyStatement.addResources(siirtotiedostoKeyArn);
    siirtotiedostoKeyStatement.addActions(
      'kms:Encrypt',
      'kms:Decrypt',
      'kms:GenerateDataKey',
      'kms:DescribeKey'
    );
    const siirtotiedostoKeyDocument = new iam.PolicyDocument();
    siirtotiedostoKeyDocument.addStatements(siirtotiedostoKeyStatement);

    const auroraClusterResourceId = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-aurora-cluster-resourceid`
    );

    const dbConnectStatement = new iam.PolicyStatement();
    dbConnectStatement.addResources(
      `arn:aws:rds-db:${props.env?.region}:${props.env?.account}:dbuser:${auroraClusterResourceId}/insert_raw_user`
    );
    dbConnectStatement.addActions('rds-db:connect');
    const dbConnectPolicyDocument = new iam.PolicyDocument();
    dbConnectPolicyDocument.addStatements(dbConnectStatement);

    const executionRole = new iam.Role(this, `${config.environment}-LambdaRole`, {
      assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
      inlinePolicies: {
        dbConnectPolicyDocument,
        siirtotiedostoBucketContentDocument,
        siirtotiedostoKeyDocument,
      },
    });
    executionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaBasicExecutionRole'
      )
    );
    executionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaVPCAccessExecutionRole'
      )
    );

    const dbEndpointName = cdk.Fn.importValue(
      `${config.environment}-opiskelijavalinnanraportointi-database-endpoint`
    );

    const siirtotiedostoLambdaName = `${config.environment}-siirtotiedostojenLataaja`;

    const siirtotiedostoLambdaLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${siirtotiedostoLambdaName}LogGroup`,
      {
        logGroupName: `/aws/lambda/${siirtotiedostoLambdaName}`,
      }
    );

    const siirtotiedostoLambda = new lambdaNodejs.NodejsFunction(
      this,
      'Transferfile loader',
      {
        functionName: siirtotiedostoLambdaName,
        entry: 'lambda/siirtotiedosto/TransferfileToDatabase.ts',
        handler: 'main',
        runtime: lambda.Runtime.NODEJS_20_X,
        architecture: lambda.Architecture.ARM_64,
        timeout: cdk.Duration.seconds(300),
        memorySize: 2048,
        vpc: props.vpc,
        securityGroups: [lambdaSecurityGroup],
        role: executionRole,
        environment: {
          host: dbEndpointName,
          database: 'ovara',
          user: 'insert_raw_user',
          port: '5432',
          batch_size: '100',
        },
        bundling: {
          commandHooks: {
            beforeBundling: (inputDir: string, outputDir: string): Array<string> => [],
            beforeInstall: (inputDir: string, outputDir: string): Array<string> => [],
            afterBundling: (inputDir: string, outputDir: string): Array<string> => [
              `cp ${inputDir}/lambda/siirtotiedosto/eu-west-1-bundle.pem ${outputDir}`,
            ],
          },
        },
      }
    );
    siirtotiedostoLambda.addEventSource(props.siirtotiedostoPutEventSource);

    const ovaraCustomMetricsNamespace = `${config.environment}-OvaraCustomMetrics`;

    const siirtotiedostoLatausOnnistuiMetricName = 'SiirtotiedostonLatausOnnistui';
    const siirtotiedostonLatausErrorMetricName = 'SiirtotiedostonLatausError';

    new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: siirtotiedostoLatausOnnistuiMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.NONE,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(
      this,
      `${config.environment}-siirtotiedostonLatausOnnistuiMetricFilter`,
      {
        filterPattern: logs.FilterPattern.spaceDelimited(
          'Timestamp',
          'uid',
          'Level',
          'text1',
          'text2',
          'rows',
          't3',
          't4',
          'system',
          't5'
        ).whereString('text1', '=', 'Kirjoitettu'),
        logGroup: siirtotiedostoLambdaLogGroup,
        metricName: siirtotiedostoLatausOnnistuiMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
        metricValue: '$rows',
        dimensions: {
          lahdejarjestelma: '$system',
        },
      }
    );

    const siirtotiedostonLatausErrorMetric = new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: siirtotiedostonLatausErrorMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.NONE,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(
      this,
      `${config.environment}-siirtotiedostonLatausErrorMetricFilter`,
      {
        filterPattern: logs.FilterPattern.anyTerm('ERROR', 'Error'),
        logGroup: siirtotiedostoLambdaLogGroup,
        metricName: siirtotiedostonLatausErrorMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
      }
    );

    const siirtotiedostonLatausErrorAlarm = new cloudwatch.Alarm(this, 'AlarmId', {
      metric: siirtotiedostonLatausErrorMetric,
      evaluationPeriods: 3,
      datapointsToAlarm: 1,
      alarmName: `${config.environment}-ovara-SiirtotiedostonLatausError`,
      alarmDescription: 'Siirtotiedoston lataamisessa tietokantaan tapahtui virhe',
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      threshold: 0,
    });
    addActionsToAlarm(siirtotiedostonLatausErrorAlarm);

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Wildcard used only for bucket contents',
      },
    ]);
  }
}
