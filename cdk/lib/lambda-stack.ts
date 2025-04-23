import * as cdk from 'aws-cdk-lib';
import { CfnOutput } from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { AccountRootPrincipal } from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as lambdaEventSources from 'aws-cdk-lib/aws-lambda-event-sources';
import * as lambdaNodejs from 'aws-cdk-lib/aws-lambda-nodejs';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface LambdaStackProps extends GenericStackProps {
  vpc: ec2.IVpc;
  siirtotiedostoBucket: s3.IBucket;
  siirtotiedostotKmsKey: kms.IKey;
  siirtotiedostoQueue: sqs.IQueue;
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

    const siirtotiedostoBucketArn = props.siirtotiedostoBucket.bucketArn;
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

    const siirtotiedostoKeyArn = props.siirtotiedostotKmsKey.keyArn;
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
        runtime: lambda.Runtime.NODEJS_22_X,
        architecture: lambda.Architecture.ARM_64,
        timeout: cdk.Duration.seconds(900),
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

    const siirtotiedostoEventSource = new lambdaEventSources.SqsEventSource(
      props.siirtotiedostoQueue,
      {
        batchSize: 1,
        maxBatchingWindow: cdk.Duration.millis(0),
        maxConcurrency: 2,
      }
    );
    siirtotiedostoLambda.addEventSource(siirtotiedostoEventSource);

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

    const lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaName = `${config.environment}-lampiYleiskayttoistenSiirtotiedostojenKopiointi`;

    const lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaName}LogGroup`,
      {
        logGroupName: `/aws/lambda/${lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaName}`,
      }
    );

    const lampiLambdaExecutionRole = new iam.Role(
      this,
      `${config.environment}-LampiLambdaRole`,
      {
        roleName: `${config.environment}-LampiLambdaRole`,
        assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
        inlinePolicies: {
          dbConnectPolicyDocument,
          siirtotiedostoBucketContentDocument,
          siirtotiedostoKeyDocument,
        },
      }
    );
    lampiLambdaExecutionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaBasicExecutionRole'
      )
    );
    lampiLambdaExecutionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        'service-role/AWSLambdaVPCAccessExecutionRole'
      )
    );

    const lampiSiirtotiedostoDLQ = new sqs.Queue(
      this,
      `${config.environment}-lampiSiirtotiedostoDLQ`,
      {
        queueName: `${config.environment}-lampiSiirtotiedostoDLQ`,
        retentionPeriod: cdk.Duration.days(14),
      }
    );

    const lampiSiirtotiedostoQueue = new sqs.Queue(
      this,
      `${config.environment}-lampiSiirtotiedostoQueue`,
      {
        queueName: `${config.environment}-lampiSiirtotiedostoQueue`,
        retentionPeriod: cdk.Duration.days(14),
        visibilityTimeout: cdk.Duration.minutes(15),
        deadLetterQueue: {
          maxReceiveCount: 10,
          queue: lampiSiirtotiedostoDLQ,
        },
      }
    );

    lampiSiirtotiedostoQueue.grantSendMessages(new AccountRootPrincipal());
    lampiSiirtotiedostoQueue.grantConsumeMessages(new AccountRootPrincipal());

    const lampiYleiskayttoistenSiirtotiedostotKopiointiLambda =
      new lambdaNodejs.NodejsFunction(
        this,
        lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaName,
        {
          functionName: lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaName,
          entry: 'lambda/lampi/YleiskayttoisetSiirtotiedostotKopiointi.ts',
          handler: 'main',
          runtime: lambda.Runtime.NODEJS_22_X,
          architecture: lambda.Architecture.ARM_64,
          timeout: cdk.Duration.seconds(900),
          memorySize: 3072,
          ephemeralStorageSize: cdk.Size.gibibytes(2),
          vpc: props.vpc,
          securityGroups: [lambdaSecurityGroup],
          role: lampiLambdaExecutionRole,
          environment: {
            environment: config.environment,
            lampiBucketName: config.siirtotiedostot.lampiBucketName,
            lampiS3Role: ssm.StringParameter.valueForStringParameter(
              this,
              `/${config.environment}/lampi-role`
            ),
            lampiS3ExternalId: ssm.StringParameter.valueForStringParameter(
              this,
              `/${config.environment}/lampi-external-id`
            ),
            ovaraBucketName: config.siirtotiedostot.ovaraBucketName,
            host: dbEndpointName,
            database: 'ovara',
            user: 'insert_raw_user',
            port: '5432',
          },
          bundling: {
            commandHooks: {
              beforeBundling: (inputDir: string, outputDir: string): Array<string> => [],
              beforeInstall: (inputDir: string, outputDir: string): Array<string> => [],
              afterBundling: (inputDir: string, outputDir: string): Array<string> => [
                `cp ${inputDir}/lambda/lampi/eu-west-1-bundle.pem ${outputDir}`,
              ],
            },
          },
        }
      );

    lampiYleiskayttoistenSiirtotiedostotKopiointiLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: ['sts:AssumeRole'],
        resources: [
          ssm.StringParameter.valueForStringParameter(
            this,
            `/${config.environment}/lampi-role`
          ),
        ],
      })
    );

    lampiYleiskayttoistenSiirtotiedostotKopiointiLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        resources: [lampiSiirtotiedostoQueue.queueArn],
        actions: ['*'],
      })
    );

    const lampiYleiskayttoistenSiirtotiedostotKopiointiEventSource =
      new lambdaEventSources.SqsEventSource(lampiSiirtotiedostoQueue, {
        batchSize: 1,
        maxBatchingWindow: cdk.Duration.millis(0),
        maxConcurrency: 2,
      });
    lampiYleiskayttoistenSiirtotiedostotKopiointiLambda.addEventSource(
      lampiYleiskayttoistenSiirtotiedostotKopiointiEventSource
    );

    const lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetricName =
      'LampiYleiskayttoistenSiirtotiedostotKopiointiError';

    const lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetric =
      new cloudwatch.Metric({
        namespace: ovaraCustomMetricsNamespace,
        metricName: lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetricName,
        period: cdk.Duration.minutes(5),
        unit: cloudwatch.Unit.NONE,
        statistic: cloudwatch.Stats.SUM,
      });

    new logs.MetricFilter(
      this,
      `${config.environment}-lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetricFilter`,
      {
        filterPattern: logs.FilterPattern.anyTerm('ERROR', 'Error'),
        logGroup: lampiYleiskayttoistenSiirtotiedostotKopiointiLambdaLogGroup,
        metricName: lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
      }
    );

    const lampiYleiskayttoistenSiirtotiedostotKopiointiErrorAlarm = new cloudwatch.Alarm(
      this,
      `${siirtotiedostonLatausErrorMetric}-alarm`,
      {
        metric: lampiYleiskayttoistenSiirtotiedostotKopiointiErrorMetric,
        evaluationPeriods: 3,
        datapointsToAlarm: 1,
        alarmName: `${config.environment}-ovara-LampiYleiskayttoistenSiirtotiedostotKopiointiError`,
        alarmDescription:
          'Lampi-palvelun siirtotiedoston kopioinnissa Ovaran S3-bucketiin tapahtui virhe',
        comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
        threshold: 0,
      }
    );
    addActionsToAlarm(lampiYleiskayttoistenSiirtotiedostotKopiointiErrorAlarm);

    const lampiTiedostoMuuttunutLambdaName = `${config.environment}-lampiTiedostoMuuttunut`;

    const lampiTiedostoMuuttunutLambdaLogGroup = new logs.LogGroup(
      this,
      `${config.environment}-${lampiTiedostoMuuttunutLambdaName}LogGroup`,
      {
        logGroupName: `/aws/lambda/${lampiTiedostoMuuttunutLambdaName}`,
      }
    );

    const lampiAuthTokenSecretName = `/${config.environment}/lambda/lampi-auth-token`;

    const lampiTiedostoMuuttunutLambda = new lambdaNodejs.NodejsFunction(
      this,
      lampiTiedostoMuuttunutLambdaName,
      {
        functionName: lampiTiedostoMuuttunutLambdaName,
        entry: 'lambda/lampi/LampiFileChangedReceiver.ts',
        handler: 'handler',
        runtime: lambda.Runtime.NODEJS_22_X,
        architecture: lambda.Architecture.ARM_64,
        timeout: cdk.Duration.seconds(60),
        memorySize: 256,
        vpc: props.vpc,
        securityGroups: [lambdaSecurityGroup],
        role: lampiLambdaExecutionRole,
        environment: {
          environment: config.environment,
          lampiSiirtotiedostoQueueUrl: lampiSiirtotiedostoQueue.queueUrl,
          lampiAuthTokenSecretName: lampiAuthTokenSecretName,
          lampiFileHandlerActive: config.lampiFileHandlerActive,
        },
        bundling: {
          commandHooks: {
            beforeBundling: (inputDir: string, outputDir: string): Array<string> => [],
            beforeInstall: (inputDir: string, outputDir: string): Array<string> => [],
            afterBundling: (inputDir: string, outputDir: string): Array<string> => [],
          },
        },
      }
    );

    lampiTiedostoMuuttunutLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        resources: [lampiSiirtotiedostoQueue.queueArn],
        actions: ['*'],
      })
    );

    const lampiTiedostoKasiteltyTable = new dynamodb.TableV2(
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

    lampiTiedostoKasiteltyTable.grantReadWriteData(lampiTiedostoMuuttunutLambda);

    const lampiAuthTokenParam = ssm.StringParameter.fromSecureStringParameterAttributes(
      this,
      'LampiAuthTokenParam',
      {
        parameterName: lampiAuthTokenSecretName,
      }
    );
    lampiAuthTokenParam.grantRead(lampiTiedostoMuuttunutLambda);

    const lampiTiedostoMuuttunutLambdaUrl = lampiTiedostoMuuttunutLambda.addFunctionUrl({
      authType: lambda.FunctionUrlAuthType.NONE,
    });

    new CfnOutput(this, 'lampiTiedostoMuuttunutLambdaUrl', {
      exportName: 'lampiTiedostoMuuttunutLambdaUrl',
      value: lampiTiedostoMuuttunutLambdaUrl.url,
    });

    const lampiTiedostoMuuttunutErrorMetricName = 'LampiTiedostoMuuttunutError';

    const lampiTiedostoMuuttunutErrorMetric = new cloudwatch.Metric({
      namespace: ovaraCustomMetricsNamespace,
      metricName: lampiTiedostoMuuttunutErrorMetricName,
      period: cdk.Duration.minutes(5),
      unit: cloudwatch.Unit.NONE,
      statistic: cloudwatch.Stats.SUM,
    });

    new logs.MetricFilter(
      this,
      `${config.environment}-lampiTiedostoMuuttunutErrorMetricFilter`,
      {
        filterPattern: logs.FilterPattern.anyTerm('ERROR', 'Error'),
        logGroup: lampiTiedostoMuuttunutLambdaLogGroup,
        metricName: lampiTiedostoMuuttunutErrorMetricName,
        metricNamespace: ovaraCustomMetricsNamespace,
      }
    );

    const lampiTiedostoMuuttunutErrorAlarm = new cloudwatch.Alarm(
      this,
      `${lampiTiedostoMuuttunutErrorMetricName}-alarm`,
      {
        metric: lampiTiedostoMuuttunutErrorMetric,
        evaluationPeriods: 3,
        datapointsToAlarm: 1,
        alarmName: `${config.environment}-ovara-lampiTiedostoMuuttunutError`,
        alarmDescription:
          'Lampi-palvelun tiedosto muuttunut -viestin käsittely epäonnistui',
        comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
        threshold: 0,
      }
    );
    addActionsToAlarm(lampiTiedostoMuuttunutErrorAlarm);

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Wildcard used only for bucket contents',
      },
      {
        id: 'AwsSolutions-SQS4',
        reason: "Messaged don't include any confidential information",
      },
      { id: 'AwsSolutions-S10', reason: '1234567890' },
    ]);
  }
}
