import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudFront from 'aws-cdk-lib/aws-cloudfront';
import * as cloudfrontOrigins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3Notifications from 'aws-cdk-lib/aws-s3-notifications';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as cdkNag from 'cdk-nag';
import { Construct } from 'constructs';

import { Config, GenericStackProps } from './config';

export interface S3StackProps extends GenericStackProps {
  slackAlarmIntegrationSnsTopic: sns.ITopic;
  zone: route53.IHostedZone;
}

export class S3Stack extends cdk.Stack {
  public readonly deploymentS3Bucket: s3.IBucket;
  public readonly siirtotiedostoBucket: s3.IBucket;
  public readonly siirtotiedostotKmsKey: kms.IKey;
  public readonly siirtotiedostoQueue: sqs.IQueue;
  constructor(scope: Construct, id: string, props: S3StackProps) {
    super(scope, id, props);

    const addActionsToAlarm = (alarm: cloudwatch.Alarm) => {
      alarm.addAlarmAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
      alarm.addOkAction(
        new cloudwatchActions.SnsAction(props.slackAlarmIntegrationSnsTopic)
      );
    };

    const config: Config = props.config;
    const certificateArn = ssm.StringParameter.fromStringParameterName(
      this,
      `${config.environment}-certificateArn`,
      `/${config.environment}/ovara-wildcard-certificate-arn`
    ).stringValue;
    const ovaraWildcardCertificate = acm.Certificate.fromCertificateArn(
      this,
      `${config.environment}-ovaraWildcardCertificate`,
      certificateArn
    );

    const siirtotiedostotBucketName = `${config.environment}-siirtotiedostot`;
    const siirtotiedostotKmsKey = new kms.Key(
      this,
      `${siirtotiedostotBucketName}-s3BucketKMSKey`,
      {
        alias: `${siirtotiedostotBucketName}-s3-bucket-kms-key`,
        enableKeyRotation: true,
      }
    );
    this.siirtotiedostotKmsKey = siirtotiedostotKmsKey;

    const siirtotiedostoS3Bucket = new s3.Bucket(this, siirtotiedostotBucketName, {
      bucketName: siirtotiedostotBucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: siirtotiedostotKmsKey,
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${siirtotiedostotBucketName}-server-access-logs`
      ),
    });

    this.siirtotiedostoBucket = siirtotiedostoS3Bucket;

    const opintopolkuAccountId = ssm.StringParameter.valueForStringParameter(
      this,
      `/${config.environment}/opintopolku-account-id`
    );

    const s3CrossAccountRole = new iam.Role(
      this,
      `${config.environment}-S3CrossAccountRole`,
      {
        assumedBy: new iam.CompositePrincipal(
          new iam.AccountRootPrincipal(),
          new iam.ArnPrincipal(`arn:aws:iam::${opintopolkuAccountId}:root`)
        ),
        roleName: 'opintopolku-s3-cross-account-role',
      }
    );

    const bucketResourceStatement = new iam.PolicyStatement();
    bucketResourceStatement.addResources(siirtotiedostoS3Bucket.bucketArn);
    bucketResourceStatement.addActions('s3:ListBucket', 's3:ListBucketVersions');
    bucketResourceStatement.addCondition('StringEquals', {
      'aws:SourceAccount': opintopolkuAccountId,
    });
    s3CrossAccountRole.addToPolicy(bucketResourceStatement);

    const objectResourceStatement = new iam.PolicyStatement();
    objectResourceStatement.addResources(`${siirtotiedostoS3Bucket.bucketArn}/*`);
    objectResourceStatement.addActions(
      's3:GetObject',
      's3:PutObject',
      's3:GetObjectAttributes',
      's3:ListMultipartUploadParts',
      's3:AbortMultipartUpload',
      's3:PutObjectTagging'
    );
    objectResourceStatement.addCondition('StringEquals', {
      'aws:SourceAccount': opintopolkuAccountId,
    });
    s3CrossAccountRole.addToPolicy(objectResourceStatement);
    new cdk.CfnOutput(this, 'SiirtotiedostoBucketArn', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-bucket-arn`,
      description: 'Siirtotiedosto bucket arn',
      value: `${siirtotiedostoS3Bucket.bucketArn}`,
    });

    const kmsResourceStatement = new iam.PolicyStatement();
    kmsResourceStatement.addResources(siirtotiedostotKmsKey.keyArn);
    kmsResourceStatement.addActions(
      'kms:Encrypt',
      'kms:Decrypt',
      'kms:GenerateDataKey',
      'kms:DescribeKey'
    );
    kmsResourceStatement.addCondition('StringEquals', {
      'aws:SourceAccount': opintopolkuAccountId,
    });
    s3CrossAccountRole.addToPolicy(kmsResourceStatement);
    new cdk.CfnOutput(this, 'SiirtotiedostoKeyArn', {
      exportName: `${config.environment}-opiskelijavalinnanraportointi-siirtotiedosto-key-arn`,
      description: 'Siirtotiedosto key arn',
      value: siirtotiedostotKmsKey.keyArn,
    });

    siirtotiedostoS3Bucket.grantReadWrite(new iam.AccountRootPrincipal());

    const deploymentS3BucketName = `${config.environment}-deployment`;
    this.deploymentS3Bucket = new s3.Bucket(this, deploymentS3BucketName, {
      bucketName: deploymentS3BucketName,
      objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      encryptionKey: new kms.Key(this, `${deploymentS3BucketName}-s3BucketKMSKey`, {
        enableKeyRotation: true,
      }),
      serverAccessLogsBucket: new s3.Bucket(
        this,
        `${deploymentS3BucketName}-server-access-logs`
      ),
    });

    const dokumentaatioBucket = new s3.Bucket(
      this,
      `${config.environment}-dokumentaatio`,
      {
        enforceSSL: true,
        bucketName: `${config.environment}-ovara-dokumentaatio`,
        objectOwnership: s3.ObjectOwnership.BUCKET_OWNER_ENFORCED,
        blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      }
    );

    const noCachePolicy = new cloudFront.CachePolicy(
      this,
      `${config.environment}-dbt-documentation-noCachePolicy`,
      {
        cachePolicyName: `${config.environment}-dbt-documentation-noCachePolicy`,
        defaultTtl: cdk.Duration.minutes(0),
        minTtl: cdk.Duration.minutes(0),
        maxTtl: cdk.Duration.minutes(0),
      }
    );

    const dokumentaatioCloudFrontToS3 = new cloudFront.Distribution(
      this,
      `${config.environment}-dokumentaatio-cloudfront-to-s3`,
      {
        defaultRootObject: 'index.html',
        defaultBehavior: {
          origin:
            cloudfrontOrigins.S3BucketOrigin.withOriginAccessControl(dokumentaatioBucket),
          viewerProtocolPolicy: cloudFront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: noCachePolicy,
        },
        domainNames: [`dokumentaatio.${config.publicHostedZone}`],
        minimumProtocolVersion: cloudFront.SecurityPolicyProtocol.TLS_V1_2_2021,
        certificate: ovaraWildcardCertificate,
      }
    );

    new route53.ARecord(this, `${config.environment}-dokumentaatio-arecord`, {
      zone: props.zone,
      recordName: 'dokumentaatio',
      target: route53.RecordTarget.fromAlias(
        new route53Targets.CloudFrontTarget(dokumentaatioCloudFrontToS3)
      ),
    });

    const siirtotiedostoDLQ = new sqs.Queue(
      this,
      `${config.environment}-siirtotiedostoDLQ`,
      {
        queueName: `${config.environment}-siirtotiedostoDLQ`,
        retentionPeriod: cdk.Duration.days(14),
      }
    );

    const siirtotiedostoQueue = new sqs.Queue(
      this,
      `${config.environment}-siirtotiedostoQueue`,
      {
        queueName: `${config.environment}-siirtotiedostoQueue`,
        retentionPeriod: cdk.Duration.days(14),
        visibilityTimeout: cdk.Duration.minutes(15),
        deadLetterQueue: {
          maxReceiveCount: 3,
          queue: siirtotiedostoDLQ,
        },
      }
    );

    const testiQueueDestination = new s3Notifications.SqsDestination(siirtotiedostoQueue);
    siirtotiedostoS3Bucket.addObjectCreatedNotification(testiQueueDestination);

    this.siirtotiedostoQueue = siirtotiedostoQueue;

    const siirtotiedostoQueueAlarm = new cloudwatch.Alarm(
      this,
      `${config.environment}-siirtotiedostoQueueAlarm`,
      {
        alarmName: `${config.environment}-siirtotiedostoQueueAlarm`,
        alarmDescription: `Alarm for ${siirtotiedostoQueue.queueName}`,
        metric: siirtotiedostoQueue.metricApproximateNumberOfMessagesVisible({
          period: cdk.Duration.minutes(15),
        }),
        threshold: 200,
        evaluationPeriods: 1,
        comparisonOperator:
          cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
        treatMissingData: cloudwatch.TreatMissingData.IGNORE,
      }
    );
    addActionsToAlarm(siirtotiedostoQueueAlarm);

    const siirtotiedostoDLQAlarm = new cloudwatch.Alarm(
      this,
      `${config.environment}-siirtotiedostoDLQAlarm`,
      {
        alarmName: `${config.environment}-siirtotiedostoDLQAlarm`,
        alarmDescription: `Alarm for dead letter ${siirtotiedostoDLQ.queueName}`,
        metric: siirtotiedostoDLQ.metricApproximateNumberOfMessagesVisible(),
        threshold: 1,
        evaluationPeriods: 1,
        comparisonOperator:
          cloudwatch.ComparisonOperator.GREATER_THAN_OR_EQUAL_TO_THRESHOLD,
        treatMissingData: cloudwatch.TreatMissingData.IGNORE,
      }
    );
    addActionsToAlarm(siirtotiedostoDLQAlarm);

    cdkNag.NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-S10', reason: 'No public access to bucket' },
      {
        id: 'AwsSolutions-IAM4',
        reason: 'Account assuming the role delegates only needed access rights',
      },
      {
        id: 'AwsSolutions-IAM5',
        reason: 'Wildcard used only for bucket contents',
      },
      {
        id: 'AwsSolutions-S1',
        reason: 'Not interested in access logs',
      },
      {
        id: 'AwsSolutions-CFR3',
        reason: 'Not interested in access logs',
      },
      {
        id: 'AwsSolutions-SQS4',
        reason: "Messaged don't include any confidential information",
      },
      {
        id: 'AwsSolutions-CFR3',
        reason: 'Not interested in access logs',
      },
      {
        id: 'AwsSolutions-CFR5',
        reason: 'False positive',
      },
    ]);
  }
}
